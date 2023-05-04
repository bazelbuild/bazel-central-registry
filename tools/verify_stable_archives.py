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

import sys
from urllib.parse import urlparse
from enum import Enum

from registry import RegistryClient

class UrlStability(Enum):
  STABLE = 1
  UNSTABLE = 2
  UNKNOWN = 3

def verify_stable_archive(url):
  parsed = urlparse(url)
  if parsed.scheme != "https" or parsed.hostname != "github.com":
    return UrlStability.UNKNOWN

  path_parts = parsed.path.split("/")

  if path_parts[3] == "releases" and path_parts[4] == "download":
    return UrlStability.STABLE

  return UrlStability.UNSTABLE

def main(argv=None):
  if argv is None:
    argv = sys.argv[1:]

  client = RegistryClient(".")

  has_failure = False
  for module_name, version in client.get_all_module_versions():
    source_url = client.get_source(module_name, version)["url"]
    stability = verify_stable_archive(source_url)
    if stability == UrlStability.UNSTABLE:
      has_failure = True
      print(f'Version `{version}` of module `{module_name}` is using an unstable source url: `{source_url}`')
      print("You should use a release archive URL in the format of `https://github.com/<ORGANIZATION>/<REPO>/releases/download/<version>/<name>.tar.gz` to ensure the archive checksum stability.")
      print("See https://blog.bazel.build/2023/02/15/github-archive-checksum.html for more context.")

  if has_failure:
    sys.exit(1)

if __name__ == "__main__":
  sys.exit(main())
