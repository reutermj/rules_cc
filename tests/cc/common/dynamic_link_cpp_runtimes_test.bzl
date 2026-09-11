"""Tests for the selection of the toolchain's C++ runtime libraries."""

load("@rules_testing//lib:analysis_test.bzl", "test_suite")
load("@rules_testing//lib:truth.bzl", "matching")
load("@rules_testing//lib:util.bzl", "util")
load("//cc:cc_binary.bzl", "cc_binary")
load("//cc:cc_library.bzl", "cc_library")
load("//cc:cc_shared_library.bzl", "cc_shared_library")
load("//tests/cc/testutil:cc_analysis_test.bzl", "cc_analysis_test")
load("//tests/cc/testutil:link_action_subject.bzl", "link_action_subject")

# The runtime libraries of the mock toolchain, see //tests/cc/testutil/toolchains:BUILD.
_STATIC_RUNTIME = "libmock_runtime.a"
_DYNAMIC_RUNTIME = "libmock_runtime.so"

_STATIC_RUNTIME_ONLY = ["static_link_cpp_runtimes"]
_DYNAMIC_RUNTIMES = ["static_link_cpp_runtimes", "dynamic_link_cpp_runtimes"]

def _setup(name, linkstatic = True, features = []):
    util.helper_target(
        cc_library,
        name = name + "_lib",
        srcs = ["a.cc"],
    )
    util.helper_target(
        cc_binary,
        name = name + "_bin",
        srcs = ["a.cc"],
        features = features,
        linkstatic = linkstatic,
        deps = [name + "_lib"],
    )
    util.helper_target(
        cc_shared_library,
        name = name + "_shared",
        features = features,
        deps = [name + "_lib"],
    )

def _shared_library_link_action(env, target):
    return env.expect.that_target(target).action_generating("{package}/lib{name}.so")

def _expect_runtime(env, target, action, runtime):
    action.inputs().contains_predicate(matching.file_basename_equals(runtime))
    for other in [_STATIC_RUNTIME, _DYNAMIC_RUNTIME]:
        if other != runtime:
            action.inputs().not_contains_predicate(matching.file_basename_equals(other))
    runfiles = env.expect.that_target(target).runfiles()
    if runtime == _DYNAMIC_RUNTIME:
        runfiles.contains_predicate(matching.str_endswith(_DYNAMIC_RUNTIME))
    else:
        runfiles.not_contains_predicate(matching.str_endswith(_DYNAMIC_RUNTIME))

# cc_shared_library links its dependencies statically and therefore gets the static runtime
# libraries, unless the toolchain enables dynamic_link_cpp_runtimes.

def _test_shared_library_gets_static_runtime(name):
    _setup(name)
    cc_analysis_test(
        name = name,
        impl = _test_shared_library_gets_static_runtime_impl,
        target = name + "_shared",
        test_features = _STATIC_RUNTIME_ONLY,
    )

def _test_shared_library_gets_static_runtime_impl(env, target):
    _expect_runtime(env, target, _shared_library_link_action(env, target), _STATIC_RUNTIME)

def _test_shared_library_gets_dynamic_runtime(name):
    _setup(name)
    cc_analysis_test(
        name = name,
        impl = _test_shared_library_gets_dynamic_runtime_impl,
        target = name + "_shared",
        test_features = _DYNAMIC_RUNTIMES,
    )

def _test_shared_library_gets_dynamic_runtime_impl(env, target):
    _expect_runtime(env, target, _shared_library_link_action(env, target), _DYNAMIC_RUNTIME)

def _test_shared_library_can_opt_out(name):
    _setup(name, features = ["-dynamic_link_cpp_runtimes"])
    cc_analysis_test(
        name = name,
        impl = _test_shared_library_can_opt_out_impl,
        target = name + "_shared",
        test_features = _DYNAMIC_RUNTIMES,
    )

def _test_shared_library_can_opt_out_impl(env, target):
    _expect_runtime(env, target, _shared_library_link_action(env, target), _STATIC_RUNTIME)

# cc_binary follows linkstatic, and dynamic_link_cpp_runtimes lifts a statically linked binary
# onto the dynamic runtime libraries as well.

def _test_binary_linkstatic_gets_static_runtime(name):
    _setup(name, linkstatic = True)
    cc_analysis_test(
        name = name,
        impl = _test_binary_linkstatic_gets_static_runtime_impl,
        target = name + "_bin",
        test_features = _STATIC_RUNTIME_ONLY,
    )

def _test_binary_linkstatic_gets_static_runtime_impl(env, target):
    _expect_runtime(env, target, link_action_subject.from_target(env, target), _STATIC_RUNTIME)

def _test_binary_linkstatic_gets_dynamic_runtime(name):
    _setup(name, linkstatic = True)
    cc_analysis_test(
        name = name,
        impl = _test_binary_linkstatic_gets_dynamic_runtime_impl,
        target = name + "_bin",
        test_features = _DYNAMIC_RUNTIMES,
    )

def _test_binary_linkstatic_gets_dynamic_runtime_impl(env, target):
    _expect_runtime(env, target, link_action_subject.from_target(env, target), _DYNAMIC_RUNTIME)

def _test_binary_dynamic_mode_gets_dynamic_runtime(name):
    _setup(name, linkstatic = False)
    cc_analysis_test(
        name = name,
        impl = _test_binary_dynamic_mode_gets_dynamic_runtime_impl,
        target = name + "_bin",
        test_features = _STATIC_RUNTIME_ONLY,
    )

def _test_binary_dynamic_mode_gets_dynamic_runtime_impl(env, target):
    _expect_runtime(env, target, link_action_subject.from_target(env, target), _DYNAMIC_RUNTIME)

def dynamic_link_cpp_runtimes_tests(name):
    test_suite(
        name = name,
        tests = [
            _test_shared_library_gets_static_runtime,
            _test_shared_library_gets_dynamic_runtime,
            _test_shared_library_can_opt_out,
            _test_binary_linkstatic_gets_static_runtime,
            _test_binary_linkstatic_gets_dynamic_runtime,
            _test_binary_dynamic_mode_gets_dynamic_runtime,
        ],
    )
