#!/usr/bin/env python3
#
# Copyright 2022 The Bazel Authors. All rights reserved.
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

import validators
import os
import sys

from registry import read
from registry import download
from registry import integrity

if __name__ == "__main__":
    # Under 'bazel run' we want to run within the source folder instead of the execroot.
    if os.getenv("BUILD_WORKSPACE_DIRECTORY"):
        os.chdir(os.getenv("BUILD_WORKSPACE_DIRECTORY"))
    if validators.url(sys.argv[1]):
        print(integrity(download(sys.argv[1])))
    else:
        print(integrity(read(sys.argv[1])))
