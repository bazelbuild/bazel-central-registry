#!/usr/bin/env python3
#
# Copyright 2021 The Bazel Authors. All rights reserved.
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
"""An interactive script to add modules into a Bazel registry.

What this script can do:
  - Initialize the Bazel Registry.
  - Generate/update the metadata.json for a module.
  - Add specified MODULE.bazel
  - Generate MODULE.bazel file with given module information
    - module name
    - version
    - compatibility level
    - dependencies
  - Generate the source.json file with given source information
    - The archive url
    - patch files
  - Add specified BUILD file for non-Bazel project by turning it into a patch.
  - Add specified presubmit.yml file.
  - Generate presubmit.yml file by given build & test targets.

"""

import argparse
import os
import sys
import time

from registry import Module
from registry import RegistryClient
from registry import log

import bcr_validation


YELLOW = "\x1b[33m"
RESET = "\x1b[0m"


def yes_or_no(question, default):
  if default:
    question += " [Y/n]: "
  else:
    question += " [y/N]: "

  var = None
  while var is None:
    user_input = ask_input(question).strip().lower()
    if user_input == "y":
      var = True
    elif user_input == "n":
      var = False
    elif not user_input:
      var = default
    else:
      print("Invalid selection: {}".format(user_input))
  return var


def ask_input(msg):
  return input(f"{YELLOW}ACTION: {RESET}{msg}")


def from_user_input():
  name = ask_input("Please enter the module name: ")
  version = ask_input("Please enter the module version: ")
  compatibility = ask_input(
      "Please enter the compatibility level [default is 0]: ") or "0"
  module = Module(name, version, compatibility)

  url = ask_input("Please enter the URL of the source archive: ")
  strip_prefix = ask_input(
      "Please enter the strip_prefix value of the archive [default None]: ") or None
  module.set_source(url, strip_prefix)

  if yes_or_no("Do you want to add patch files?", False):
    patches = ask_input("Please enter patch file paths, separated by `,`: ")
    for patch in patches.strip().split(","):
      module.add_patch(patch.strip())
    patch_strip = ask_input("Please enter the patch strip number [Default is 1, compatible with git generated "
                            "patches]: ") or "1"
    module.set_patch_strip(int(patch_strip.strip()))

  if yes_or_no("Do you want to add a BUILD file?", False):
    build_file = ask_input(
        "Please enter the path of the BUILD file to be added: ")
    module.set_build_file(build_file.strip())

  if yes_or_no("Do you want to specify a MODULE.bazel file?", False):
    path = ask_input("Please enter the MODULE.bazel file path: ").strip()
    module.set_module_dot_bazel(path)
  else:
    if yes_or_no("Do you want to specify dependencies for this module?", False):
      deps = ask_input(
          "Please enter dependencies in the form of <name>@<version>, separated by `,`: ")
      for dep in deps.strip().split(","):
        name, version = dep.split("@")
        module.add_dep(name, version)

  presubmit_url = "https://github.com/bazelbuild/bazel-central-registry/tree/main/docs#presubmit"
  if yes_or_no(f"Do you want to specify an existing presubmit.yml file? (See {presubmit_url})", False):
    path = ask_input("Please enter the presubmit.yml file path: ").strip()
    module.set_presubmit_yml(path)
  else:
    first = True
    while not module.build_targets:
      if not first:
        print("Build targets cannot be empty, please re-enter!")
      first = False
      build_targets = ask_input(
          "Please enter a list of build targets you want to expose to downstream users, separated by `,`: ")
      for target in build_targets.strip().split(","):
        if target:
          module.add_build_target(target)

    if yes_or_no("Do you have a test module in your source archive?", True):
      module.test_module_path = ask_input(
          "Please enter the test module path in your source archive: ")
      first = True
      while not (module.test_module_build_targets or module.test_module_test_targets):
        if not first:
          print("Build targets and test targets cannot both be empty, please re-enter!")
        first = False
        build_targets = ask_input(
            "Please enter a list of build targets for the test module, separated by `,`: ")
        for target in build_targets.strip().split(","):
          if target:
            module.add_test_module_build_target(target)
        test_targets = ask_input(
            "Please enter a list of test targets for the test module, separated by `,`: ")
        for target in test_targets.strip().split(","):
          if target:
            module.add_test_module_test_target(target)
  return module


def get_maintainers_from_input():
  maintainers = []
  prefix = "a"
  explain = " (See https://github.com/bazelbuild/bazel-central-registry/tree/main/docs/bcr-policies.md#become-a-module-maintainer)"
  while yes_or_no(f"Do you want to add {prefix} maintainer for this module?{explain}", False):
    maintainer = {}
    name = ask_input("Please enter maintainer name: ")
    maintainer["name"] = name
    email = ask_input("Please enter the maintainer's email address: ")
    maintainer["email"] = email
    username = ask_input(
        "(Optional) Please enter the maintainer's github username: ")
    if username:
      maintainer["github"] = username
    maintainers.append(maintainer)
    prefix = "another"
    explain = ""
  return maintainers


def main(argv=None):
  if argv is None:
    argv = sys.argv[1:]

  parser = argparse.ArgumentParser()
  parser.add_argument("--registry", type=str, default=".",
                      help="Specify the root path of the registry (default: the current working directory).")
  parser.add_argument(
      "--input", type=str, help="Take module information from a json file, which can be generated from previous input.")

  args = parser.parse_args(argv)

  if args.input:
    log(f"Getting module information from {args.input}...")
    module = Module()
    module.from_json(args.input)
  else:
    log("Getting module information from user input...")
    module = from_user_input()
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    log(f"Saving module information to {module.name}.{timestamp}.json")
    log(f"You can use it via --input={module.name}.{timestamp}.json")
    module.dump(f"{module.name}.{timestamp}.json")

  client = RegistryClient(args.registry)

  if not client.contains(module.name):
    log(f"{module.name} is a new Bazel module...")
    homepage = ask_input(
        "Please enter the homepage url for this module: ").strip()
    maintainers = get_maintainers_from_input()
    source_repository = ""
    if module.url.startswith("https://github.com/"):
      parts = module.url.split("/")
      source_repository = "github:" + parts[3] + "/" + parts[4]
    client.init_module(module.name, maintainers, homepage, source_repository)

  client.add(module, override=True)
  log(f"{module.name} {module.version} is added into the registry.")

  log(f"Running ./tools/bcr_validation.py --check={module.name}@{module.version} --fix")
  bcr_validation.main([f"--check={module.name}@{module.version}", "--fix"])


if __name__ == "__main__":
  # Under 'bazel run' we want to run within the source folder instead of the execroot.
  if os.getenv("BUILD_WORKSPACE_DIRECTORY"):
    os.chdir(os.getenv("BUILD_WORKSPACE_DIRECTORY"))
  sys.exit(main())
