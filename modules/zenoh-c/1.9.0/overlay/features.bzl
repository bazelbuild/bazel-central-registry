# Copyright 2026 Open Source Robotics Foundation, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@crates_zenoh_c//:data.bzl", "DEP_DATA")

_EXTRA_ZENOH_C_FEATURES = [
    "shared-memory",
    "transport_serial",
    "transport_vsock",
    "unstable",
]

def _dedupe(items):
    result = []
    seen = {}
    for item in items:
        if item not in seen:
            result.append(item)
            seen[item] = True
    return result

def zenoh_c_crate_features(extra = []):
    return _dedupe(DEP_DATA[""]["crate_features"] + _EXTRA_ZENOH_C_FEATURES + extra)

def opaque_type_crate_features():
    return zenoh_c_crate_features(extra = ["panic"])
