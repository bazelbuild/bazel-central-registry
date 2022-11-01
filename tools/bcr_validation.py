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
"""A script to perform BCR validations for Bazel modules

Validations performed are:
  - Verify versions in metadata.json matches existing versions
  - Verify the source archive URL match the source repositories
  - Verify the source archive URL is stable
  - Verify if the presubmit.yml file matches the previous version
    - If not, we should require BCR maintainer review.
"""

import argparse
import sys
import os

from enum import Enum
from difflib import unified_diff
from urllib.parse import urlparse

from registry import RegistryClient
from registry import Version
from registry import download
from registry import integrity
from verify_stable_archives import UrlStability
from verify_stable_archives import verify_stable_archive


class BcrValidationResult(Enum):
  GOOD = 1
  NEED_BCR_MAINTAINER_REVIEW = 2
  FAILED = 3

RED = "\x1b[31m"
GREEN = "\x1b[32m"
YELLOW = "\x1b[33m"
RESET = "\x1b[0m"

COLOR = {
  BcrValidationResult.GOOD: GREEN,
  BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW: YELLOW,
  BcrValidationResult.FAILED: RED,
}

def print_collapsed_group(name):
    print("\n\n--- {0}\n\n".format(name))

def print_expanded_group(name):
    print("\n\n+++ {0}\n\n".format(name))

def parse_module_versions(registry, check_all, inputs):
  """Parse module versions to be validated from input."""
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

def print_validation_result(result):
  for code, message in result:
    color = COLOR[code]
    print(f"{color}{code}{RESET}: {message}\n")

class BcrValidationException(Exception):
  """
  Raised whenever we should stop the validation immediately.
  """

def verify_module_existence(registry, module_name, version):
  """Verify the directory exists and the version is recorded in metadata.json."""
  validation_results = []
  if not registry.contains(module_name, version):
    validation_results.append((BcrValidationResult.FAILED, f"{module_name}@{version} doesn't exist."))
    print_validation_result(validation_results)
    raise BcrValidationException("The module to be checked doesn't exist!")
  versions = registry.get_metadata(module_name)["versions"]
  if version not in versions:
    validation_results.append((BcrValidationResult.FAILED, f"Version {version} is not recorded in {module_name}'s metadata.json file."))
  else:
    validation_results.append((BcrValidationResult.GOOD, "The module exists and is recorded in metadata.json."))
  return validation_results

def verify_source_archive_url(registry, module_name, version):
  # Verify the source archive URL matches the github repo. For now, we only support github repositories check.
  validation_results = []
  source_url = registry.get_source(module_name, version)["url"]
  source_repositories = registry.get_metadata(module_name).get("repository", [])
  matched = False
  for source_repository in source_repositories:
    if matched:
      break
    repo_type, repo_path = source_repository.split(":")
    if repo_type == "github":
      parts = urlparse(source_url)
      matched = parts.scheme == "https" and parts.netloc == "github.com" and os.path.abspath(parts.path).startswith(f"/{repo_path}/")
  if not matched:
    validation_results.append((BcrValidationResult.FAILED, f"The source URL of {module_name}@{version} ({source_url}) doesn't match any of the module's source repositories {source_repositories}."))
  else:
    validation_results.append((BcrValidationResult.GOOD, "The source URL matches one of the source repositories."))

  # Verify source archive URL is stable.
  if verify_stable_archive(source_url) == UrlStability.UNSTABLE:
    validation_results.append((BcrValidationResult.FAILED,
                        f"{module_name}@{version} is using an unstable source url: `{source_url}`.\n"
                        + "The source url should follow the format of `https://github.com/<ORGANIZATION>/<REPO>/archive/refs/tags/<TAG>.tar.gz` to retrieve a source archive that is guaranteed by GitHub to be stable over time.\n"
                        + "See https://github.com/bazel-contrib/SIG-rules-authors/issues/11#issuecomment-1029861300 for more context."))
  else:
    validation_results.append((BcrValidationResult.GOOD, "The source URL doesn't look unstable."))
  return validation_results

def verify_source_archive_integrity(registry, module_name, version):
  """Verify the integrity value of the URL is correct."""
  validation_results = []
  source_url = registry.get_source(module_name, version)["url"]
  expected_integrity = registry.get_source(module_name, version)["integrity"]
  real_integrity = integrity(download(source_url))
  if real_integrity != expected_integrity:
    validation_results.append((BcrValidationResult.FAILED, f"{module_name}@{version}'s source archive `{source_url}` has expected integrity value `{expected_integrity}`, but the real integrity value is `{real_integrity}`!"))
  else:
    validation_results.append((BcrValidationResult.GOOD, "The source archive's integrity value matches."))
  return validation_results

def verify_presubmit_yml_change(registry, module_name, version):
  """Verify if the presubmit.yml is the same as the previous version."""
  validation_results = []
  versions = registry.get_metadata(module_name)["versions"]
  versions.sort(key=Version)
  index = versions.index(version)
  if index == 0:
    validation_results.append((BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW, f"Module version {module_name}@{version} is new, the presubmit.yml file should be reviewed by a BCR maintainer."))
  elif index > 0:
    pre_version = versions[index - 1]
    previous_presubmit_yml = registry.get_presubmit_yml_path(module_name, pre_version)
    previous_presubmit_content = open(previous_presubmit_yml, "r").readlines()
    current_presubmit_yml = registry.get_presubmit_yml_path(module_name, version)
    current_presubmit_content = open(current_presubmit_yml, "r").readlines()
    diff = list(unified_diff(previous_presubmit_content, current_presubmit_content, fromfile=str(previous_presubmit_yml), tofile = str(current_presubmit_yml)))
    if diff:
      validation_results.append((BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW,
                          f"The presubmit.yml file of {module_name}@{version} doesn't match its previous version {module_name}@{pre_version}, the following presubmit.yml file change should be reviewed by a BCR maintainer.\n"
                          + "    " + "    ".join(diff)))
    else:
      validation_results.append((BcrValidationResult.GOOD, "The presubmit.yml file matches the previous version."))
  return validation_results

def validate_module(registry, module_name, version):
  print_expanded_group(f"Validating {module_name}@{version}")

  validation_results = []
  validation_results.extend(verify_module_existence(registry, module_name, version))
  validation_results.extend(verify_source_archive_url(registry, module_name, version))
  validation_results.extend(verify_source_archive_integrity(registry, module_name, version))
  validation_results.extend(verify_presubmit_yml_change(registry, module_name, version))

  print_validation_result(validation_results)
  return validation_results

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
    help="Specify a Bazel module version you want to perform the BCR check on."
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

  # Parse what module versions we should validate
  module_versions = parse_module_versions(registry, args.check_all, args.check)
  print_expanded_group("Module versions to be validated:")
  for name, version in module_versions:
    print(f"{name}@{version}")

  # Validate given module version.
  validation_results = []
  for name, version in module_versions:
    validation_results.extend(validate_module(registry, name, version))

  # Calculate the return code
  # 0: All good
  # 1: BCR validation failed
  # 42: BCR validation passes, but some changes need BCR maintainer review before trigging follow up BCR presubmit jobs.
  result_codes = [code for code, _ in validation_results]
  if BcrValidationResult.FAILED in result_codes:
    return 1
  if BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW in result_codes:
    # Use a special return code to avoid conflict with other error code
    return 42
  return 0

if __name__ == "__main__":
  sys.exit(main())
