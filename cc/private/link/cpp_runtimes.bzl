# Copyright 2024 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Selection between the toolchain's static and dynamic C++ runtime libraries."""

load("//cc/private/link:target_types.bzl", "LINKING_MODE")

# With `static_link_cpp_runtimes`, the toolchain supplies the C++ runtime libraries
# (`cc_toolchain.static_runtime_lib` and `dynamic_runtime_lib`), and a link gets the static ones in
# static linking mode and the dynamic ones in dynamic linking mode. A toolchain that enables this
# feature makes a link get the dynamic runtime libraries in static linking mode as well, while the
# dependencies stay statically linked, the way a compiler driver links the runtime by default. It is
# the counterpart of `dynamic_link_msvcrt` for toolchain-supplied runtimes, and the only way to link
# the runtime dynamically into a cc_shared_library, whose dependencies are always linked statically.
# A target turns it off again with `features = ["-dynamic_link_cpp_runtimes"]`.
DYNAMIC_LINK_CPP_RUNTIMES = "dynamic_link_cpp_runtimes"

def links_cpp_runtimes_dynamically(feature_configuration, linking_mode):
    """Whether a link gets the toolchain's dynamic rather than static C++ runtime libraries.

    Args:
        feature_configuration: (FeatureConfiguration) `feature_configuration` to be queried.
        linking_mode: (LINKING_MODE) Linking mode used for the dependencies.

    Returns:
        (bool) True for the dynamic runtime libraries.
    """
    return linking_mode == LINKING_MODE.DYNAMIC or feature_configuration.is_enabled(DYNAMIC_LINK_CPP_RUNTIMES)
