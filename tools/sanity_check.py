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
"""A script to perform sanity checks for Bazel modules

Sanity checks performed are:
  - Verify versions in metadata.json matches existing versions
  - Verify the source archive URL match the source repositories
  - Verify the source archive URL is stable
  - Verify if the presubmit.yml file matches the previous version
    - If not, we should require BCR maintainer review.
"""

import argparse
import sys

from enum import Enum
from difflib import unified_diff

from registry import RegistryClient
from registry import Version
from verify_stable_archives import UrlStability
from verify_stable_archives import verify_stable_archive


class SanityCheckResult(Enum):
  ALL_GOOD = 1
  NEED_BCR_MAINTAINER_REVIEW = 2
  FAILED = 3

RED = "\x1b[31m"
GREEN = "\x1b[32m"
YELLOW = "\x1b[33m"
RESET = "\x1b[0m"

COLOR = {
  SanityCheckResult.ALL_GOOD: GREEN,
  SanityCheckResult.NEED_BCR_MAINTAINER_REVIEW: YELLOW,
  SanityCheckResult.FAILED: RED,
}

def print_collapsed_group(name):
    print("\n\n--- {0}\n\n".format(name))

def print_expanded_group(name):
    print("\n\n+++ {0}\n\n".format(name))

def parse_module_versions(registry, check_all, inputs):
  """Parse module versions to be checked from input."""
  if check_all:
    return registry.get_all_module_versions()
  result = []
  for s in inputs:
    if "@" in s:
      name, version = s.split("@")
      result.append((name, version))
    else:
      result.extend(registry.get_module_versions(s))
  return result

def print_check_result(result):
  for code, message in result:
    color = COLOR[code]
    print(f"{color}{code}{RESET}: {message}\n")

def sanity_check(registry, module_name, version):
  print_collapsed_group(f"Checking {module_name}@{version}")

  check_results = []

  # Check the version is recorded in metadata.json and the directory entry exists.
  versions = registry.get_metadata(module_name)["versions"]
  if version not in versions:
    check_results.append((SanityCheckResult.FAILED, f"Version {version} is not recorded in {module_name}'s metadata.json file."))
  if not registry.contains(module_name, version):
    check_results.append((SanityCheckResult.FAILED, f"{module_name}@{version} doesn't exist."))
  if check_results:
    print_check_result(check_results)
    return check_results

  # Verify the source archive URL matches the github repo. For now, we only support github repositories check.
  source_url = registry.get_source(module_name, version)["url"]
  source_repositories = registry.get_metadata(module_name).get("repository", [])
  matched = False
  for source_repository in source_repositories:
    if matched:
      break
    repo_type, repo_path = source_repository.split(":")
    if repo_type == "github":
      matched = source_url.startswith(f"https://github.com/{repo_path}/")
  if not matched:
    check_results.append((SanityCheckResult.FAILED, f"The source URL of {module_name}@{version} ({source_url}) doesn't match any of the module's source repositories {source_repositories}."))

  # Check source archive URL is stable
  if verify_stable_archive(source_url) == UrlStability.UNSTABLE:
      check_results.append((SanityCheckResult.FAILED,
                          f"{module_name}@{version} is using an unstable source url: `{source_url}`.\n"
                          + "The source url should follow the format of `https://github.com/<ORGANIZATION>/<REPO>/archive/refs/tags/<TAG>.tar.gz` to retrieve a source archive that is guaranteed by GitHub to be stable over time.\n"
                          + "See https://github.com/bazel-contrib/SIG-rules-authors/issues/11#issuecomment-1029861300 for more context."))

  # Check if the presubmit.yml is the same as the previous version.
  versions.sort(key=Version)
  index = versions.index(version)
  if index == 0:
    check_results.append((SanityCheckResult.NEED_BCR_MAINTAINER_REVIEW, f"Module version {module_name}@{version} is new, the presubmit.yml file should be reviewed by a BCR maintainer."))
  elif index > 0:
    pre_version = versions[index - 1]
    previous_presubmit_yml = registry.get_presubmit_yml_path(module_name, pre_version)
    previous_presubmit_content = open(previous_presubmit_yml, "r").readlines()
    current_presubmit_yml = registry.get_presubmit_yml_path(module_name, version)
    current_presubmit_content = open(current_presubmit_yml, "r").readlines()
    diff = list(unified_diff(previous_presubmit_content, current_presubmit_content, fromfile=str(previous_presubmit_yml), tofile = str(current_presubmit_yml)))
    if diff:
      check_results.append((SanityCheckResult.NEED_BCR_MAINTAINER_REVIEW,
                          f"The presubmit.yml file of {module_name}@{version} doesn't match its previous version {module_name}@{pre_version}, the following presubmit.yml file change should be reviewed by a BCR maintainer.\n"
                          + "".join(diff)))

  if not check_results:
    check_results.append((SanityCheckResult.ALL_GOOD, "Everything looks good!"))

  print_check_result(check_results)
  return check_results

def main(argv=None):
  if argv is None:
    argv = sys.argv[1:]

  parser = argparse.ArgumentParser()
  parser.add_argument(
    "--registry",
    type=str,
    default=".",
    help="Specify the root path of the registry (default: the current working directory).")
  parser.add_argument(
    "--check",
    type=str,
    action = "append",
    help="Specify a Bazel module version you want to perform the sanity check on."
    + " (e.g. bazel_skylib@1.3.0). If no version is specified, all versions of that module are checked."
    + " This flag can be repeated to accept multiple module versions.")
  parser.add_argument(
    "--check_all",
    action="store_true",
    help="Check all Bazel modules in the registry, ignore other --check flags.")

  args = parser.parse_args(argv)

  if not args.check_all and not args.check:
    parser.print_help()
    return -1

  registry = RegistryClient(args.registry)

  # Parse what module versions we should check
  module_versions = parse_module_versions(registry, args.check_all, args.check)
  print_collapsed_group("Module versions to be checked:")
  for name, version in module_versions:
    print(f"{name}@{version}")

  # Perform checks on given module version.
  check_results = []
  for name, version in module_versions:
    check_results.extend(sanity_check(registry, name, version))

  # Calculate the return code
  # 0: All good
  # 1: Sanity check failed
  # 42: Sanity check pass, but some changes need BCR maintainer review before trigging follow up BCR presubmit jobs.
  result_codes = [code for code, _ in check_results]
  if SanityCheckResult.FAILED in result_codes:
    return 1
  if SanityCheckResult.NEED_BCR_MAINTAINER_REVIEW in result_codes:
    # Use a special return code to avoid conflict with other error code
    return 42
  return 0

if __name__ == "__main__":
  sys.exit(main())
