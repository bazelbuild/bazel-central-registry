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
# pylint: disable=invalid-name
# pylint: disable=line-too-long
# pylint: disable=missing-function-docstring

import os
import sys

from registry import RegistryClient

def main():
  client = RegistryClient(".")
  for name, version in client.get_all_module_versions(include_yanked=False):
    print(client.get_source(name, version)["url"])

if __name__ == "__main__":
  # Under 'bazel run' we want to run within the source folder instead of the execroot.
  if os.getenv("BUILD_WORKSPACE_DIRECTORY"):
    os.chdir(os.getenv("BUILD_WORKSPACE_DIRECTORY"))
  sys.exit(main())
