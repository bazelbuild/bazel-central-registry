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

import json
import os
import pathlib
import sys

import validators
from registry import download, integrity, read

if __name__ == "__main__":
    # Under 'bazel run' we want to run within the source folder instead of the execroot.
    if os.getenv("BUILD_WORKSPACE_DIRECTORY"):
        os.chdir(os.getenv("BUILD_WORKSPACE_DIRECTORY"))
    target = sys.argv[1]
    if validators.url(target):
        print(integrity(download(target)))
    elif (file := pathlib.Path(target)).is_file() and file.name == "source.json":
        source = json.loads(file.read_text())
        source["integrity"] = integrity(download(source["url"]))
        patch_base = file.parent / "patches"
        for patch_name in source.get("patches", []):
            source["patches"][patch_name] = integrity(read(patch_base / patch_name))
        file.write_text(json.dumps(source, indent=2) + "\n")
    else:
        print(integrity(read(target)))
