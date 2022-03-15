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


import importlib.util
import json
import locale
import pathlib
import re
import subprocess
import sys
import tempfile
import os

from registry import RegistryClient

# The default workspace name, will be popluated in do_preparation()
WORKSPACE_NAME = "__main__"

# The registry client points to the bazel central registry repo
REGISTRY_CLIENT = RegistryClient(pathlib.Path(__file__).parent.parent)

# Set USE_BAZEL_SYNC env var to use bazel sync command to generate the resolved deps file.
# Using bazel sync will generate information for bind usages in the WORKSPACE, which helps
# the migration. But bazel sync may take a long time and fail on specific platforms because
# it fetch every repository defined in the WORKSPACE file.
USE_BAZEL_SYNC = os.environ.get("USE_BAZEL_SYNC", False)

COMMON_REPO_TO_MODULE_MAP = {
    "io_bazel_skydoc": "stardoc",
    "com_google_absl": "abseil-cpp",
    "com_github_cares_cares": "c-ares",
}


class BzlmodMigrationException(Exception):
  """
  Raised whenever something goes wrong and we should exit with an error.
  """
  pass


def assertExitCode(exit_code, expected_exit_code, error_message, stderr):
  if exit_code != expected_exit_code:
    error(f"Command exited with {exit_code}, expected {expected_exit_code}:")
    eprint(stderr)
    raise BzlmodMigrationException(error_message)


def eprint(*args, **kwargs):
  """
  Print to stderr and flush (just in case).
  """
  print(*args, flush=True, file=sys.stderr, **kwargs)


GREEN = "\x1b[32m"
YELLOW = "\x1b[33m"
RED = "\x1b[31m"
RESET = "\x1b[0m"


def info(msg):
  eprint(f"{GREEN}INFO: {RESET}{msg}")


def warning(msg):
  eprint(f"{YELLOW}WARNING: {RESET}{msg}")


def error(msg):
  eprint(f"{RED}ERROR: {RESET}{msg}")


def ask_input(msg):
  return input(f"{YELLOW}ACTION: {RESET}{msg}")


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
      eprint(f"Invalid selection: {user_input}")
  return var


def scratch_file(file_path, lines=None, mode="w"):
  """Write to a file"""
  abspath = pathlib.Path(file_path)
  with open(abspath, mode) as f:
    if lines:
      for l in lines:
        f.write(l)
        f.write('\n')
  return abspath


def execute_command(args, cwd=None, env=None, shell=False, executable=None):
  info("Executing command: " + " ".join(args))
  with tempfile.TemporaryFile() as stdout:
    with tempfile.TemporaryFile() as stderr:
      proc = subprocess.Popen(
          args,
          executable=executable,
          stdout=stdout,
          stderr=stderr,
          cwd=cwd,
          env=env,
          shell=shell)
      exit_code = proc.wait()

      stdout.seek(0)
      stdout_result = stdout.read().decode(locale.getpreferredencoding())
      stderr.seek(0)
      stderr_result = stderr.read().decode(locale.getpreferredencoding())
      return exit_code, stdout_result, stderr_result


def print_repo_definition(dep):
  """Print the repository info to stdout and return the repository definition."""
  # Parse the repository rule class (rule name, and the label for the bzl file where the rule is defined.)
  rule_class = dep["original_rule_class"]
  if rule_class.find("%") != -1:
    # Starlark rule
    file_label, rule_name = rule_class.split("%")
    # If the original macro is not publicly visible, we trace back to fine a visible one.
    if rule_name.startswith("_"):
      def_info = dep["definition_information"].split("\n")
      def_info.reverse()
      for line in def_info:
        s = re.match(r"^  (.+):[0-9]+:[0-9]+: in ([^\_<].+)$", line)
        if s:
          new_file_name, new_rule_name = s.groups()
          if new_file_name.endswith(file_label.split("//")[1].replace(":", "/")):
            rule_name = new_rule_name
          else:
            warning(
                f"A visible macro for {rule_name} is defined in a different bzl file `{new_file_name}` other than `{file_label}`, you have to find out the correct label for `{new_file_name}` manually.")
          break
  else:
    # Native rule
    file_label = None
    rule_name = rule_class

  # Generate the repository definition lines.
  repo_def = []
  if file_label:
    repo_def.append(f"load(\"{file_label}\", \"{rule_name}\")")
  repo_def.append(f"{rule_name}(")
  for key, value in dep["original_attributes"].items():
    if not key.startswith("generator_"):
      value_str = json.dumps(value, indent=4)
      # Fix indentation
      if value_str.endswith("}") or value_str.endswith("]"):
        value_str = value_str[:-1] + "  " + value_str[-1]
      # Fix boolean format
      if value_str == "false" or value_str == "true":
        value_str = value_str[0].upper() + value_str[1:]
      repo_def.append(f"  {key} = {value_str},")
  repo_def.append(")")

  header = "----- Repository information for @%s in the WORKSPACE file -----" % dep[
      "original_attributes"]["name"]
  eprint(header)
  if "definition_information" in dep:
    eprint(dep["definition_information"])
  eprint("Repository definition:")
  for line in repo_def:
    eprint(line)
  eprint("-" * len(header))

  return repo_def


def detect_unavailable_repo_error(stderr):
  for line in stderr.split("\n"):
    s = re.search(
        r"Repository '@([A-Za-z0-9_-]+)' is not visible from repository '@([A-Za-z0-9_-]*)'", line)
    if s:
      eprint(line)
      return s.groups()
    s = re.search(
        r"@([A-Za-z0-9_-]+) is not visible from repository `@([A-Za-z0-9_-]*)`", line)
    if s:
      eprint(line)
      return s.groups()
    s = re.search(
        r"Repository '@([A-Za-z0-9_-]+)' is not defined and referenced by '@([A-Za-z0-9_-]*)//.*'", line)
    if s:
      eprint(line)
      return s.groups()
    s = re.search(
        r"Repository '@([A-Za-z0-9_-]+)' is not defined", line)
    if s:
      eprint(line)
      return s.groups()[0], ""
    s = re.search(
        r"This could either mean you have to add the '@([A-Za-z0-9_-]+)' repository with a statement like `http_archive`", line)
    if s:
      eprint(line)
      return s.groups()[0], ""
  return None, None


def address_unavailable_repo_error(repo, resolved_deps):
  error(f"@{repo} is not visible from Bzlmod")

  # Check if it's the original main repo name
  if repo == WORKSPACE_NAME:
    warning(
        f"Please remove the usages of refering your own repo via `@{repo}//`, targets should be referenced directly with `//`. ")
    eprint("If it's used in a macro, you can use `Label(\"//foo/bar\")` to make sure it alwasy points to your repo no matter where the macro is used.")
    eprint(f"You can temporarily work around this by changing your module name to {WORKSPACE_NAME} and adding `workspace(name = '{WORKSPACE_NAME}')` in the WORKSPACE.bzlmod file.")
    return yes_or_no("Do you wish to retry the build?", True)

  # Special check for local_config_cc
  if repo == "local_config_cc":
    info("Due to https://github.com/bazelbuild/bazel/issues/14279, you can fix this by overriding --crosstool_top and --host_crosstool_top with: ")
    crosstool_flags = [
        "build:bzlmod --crosstool_top=@rules_cc.0.0.1.cc_configure.local_config_cc//:toolchain",
        "build:bzlmod --host_crosstool_top=@rules_cc.0.0.1.cc_configure.local_config_cc//:toolchain",
    ]
    for line in crosstool_flags:
      eprint("    " + line)
    if yes_or_no("Do you wish to override --crosstool_top and --host_crosstool_top in .bazelrc?", True):
      crosstool_flags = [
          "# TODO: The following should be removed after fixing https://github.com/bazelbuild/bazel/issues/14279"] + crosstool_flags
      scratch_file(".bazelrc", crosstool_flags, mode="a")
      warning("Done, you may need to fix the rules_cc version number in .bazelrc.")
      return True

  # Special check for local_config_xcode
  if repo == "local_config_xcode":
    info("Due to https://github.com/bazelbuild/bazel/issues/14279, you can fix this by overriding --xcode_version_config with: ")
    xcode_flag = [
        "build:bzlmod --xcode_version_config=@rules_cc.0.0.1.cc_configure.local_config_xcode//:host_xcodes",
    ]
    for line in xcode_flag:
      eprint("    " + line)
    if yes_or_no("Do you wish to override --xcode_version_config in .bazelrc?", True):
      xcode_flag = [
          "# TODO: The following should be removed after fixing https://github.com/bazelbuild/bazel/issues/14279"] + xcode_flag
      scratch_file(".bazelrc", xcode_flag, mode="a")
      warning("Done, you may need to fix the rules_cc version number in .bazelrc.")
      return True

  # Print the repo definition in the original WORKSPACE file
  repo_def = []
  for dep in resolved_deps:
    if dep["original_attributes"]["name"] == repo:
      repo_def = print_repo_definition(dep)
      break
  if not repo_def:
    error(
        f"Repository definition for {repo} isn't found in ./resolved_deps.py file, try delete this file and rerun the script.")
    raise BzlmodMigrationException(
        f"Repository definition for {repo} isn't found!")

  # Check if a module is already available in the registry.
  found_module = None
  for module_name in REGISTRY_CLIENT.get_all_modules():
    # The module name is usually a substring of the repo name when they are different.
    if repo.find(module_name) != -1 or COMMON_REPO_TO_MODULE_MAP.get(repo) == module_name:
      found_module = module_name

  if found_module:
    metadata = REGISTRY_CLIENT.get_metadata(found_module)
    version = metadata["versions"][-1]
    repo_name = "" if repo == found_module else f", repo_name = \"{repo}\""
    bazel_dep_line = f"bazel_dep(name = \"{found_module}\", version = \"{version}\"{repo_name})"
    info(f"Found module `{found_module}` in the registry, available versions are " +
         str(metadata["versions"]))
    info(f"This can be introudced via a bazel_dep definition:")
    eprint(f"    {bazel_dep_line}")

    if yes_or_no("Do you wish to add the bazel_dep definiton to the MODULE.bazel file?", True):
      scratch_file("MODULE.bazel", [bazel_dep_line], mode="a")
      return True
  else:
    info(f"{repo} isn't found in the registry.")

  # TODO: ask user if the dependency should be introudced via module extension.

  # Ask user if this dep should be added to the WORKSPACE.bzlmod for now.
  if yes_or_no("Do you wish to add the repo definition to WORKSPACE.bzlmod for later migration?", True):
    repo_def = ["", "# TODO: Migrated to Bzlmod"] + repo_def
    scratch_file("WORKSPACE.bzlmod", repo_def, mode="a")
  else:
    info("Please manually add this dependency in MODULE.bazel file")
    return yes_or_no("Do you wish to retry the build after fixes?", True)
  return True


def detect_bind_issue(stderr):
  """Search for error message that maybe caused by missing bind statements and return the missing target."""
  for line in stderr.split("\n"):
    s = re.search(r"no such target '(//external:[A-Za-z0-9_-]+)'", line)
    if s:
      eprint(line)
      return s.groups()[0]
  return None


def address_bind_issue(bind_target, resolved_repos):
  warning(
      f"A bind target detected: {bind_target}, please fix manually! You should just reference the actual target directory instead of using //external package.")

  name = bind_target.split(":")[1]
  bind_def = None
  for dep in resolved_repos:
    if dep["original_rule_class"] == "bind" and dep["original_attributes"]["name"] == name:
      bind_def = print_repo_definition(dep)
      break

  if bind_def:
    bind_def = ["", "# TODO: Remove the following bind usage"] + bind_def
    if yes_or_no("Do you wish to add the bind definition to WORKSPACE.bzlmod for later migration?", False):
      scratch_file("WORKSPACE.bzlmod", bind_def, mode="a")
      return True
  else:
    info(
        f"Bind definition for {bind_target} isn't found in ./resolved_deps.py file, to get more verbose info please delete "
        "resolved_deps.py and rerun the script after changing `USE_BAZEL_SYNC` to True in the migration script.")

  return yes_or_no("Do you wish to retry the build after fixes?", True)


def grep_file(file_path, pattern):
  f = pathlib.Path(file_path)
  if not f.exists():
    return []
  result = []
  with open(f, "r") as i:
    for line in i:
      if re.search(pattern, line):
        result.append(line)
  return result


def _extract_version_number(bazel_version):
  """Extracts the semantic version number from a version string
  Args:
    bazel_version: the version string that begins with the semantic version
      e.g. "1.2.3rc1 abc1234" where "abc1234" is a commit hash.
  Returns:
    The semantic version string, like "1.2.3".
  """
  for i in range(len(bazel_version)):
    c = bazel_version[i]
    if not (c.isdigit() or c == "."):
      return bazel_version[:i]
  return bazel_version


def _parse_bazel_version(bazel_version):
  """Parses a version string into a 3-tuple of ints
  int tuples can be compared directly using binary operators (<, >).
  Args:
    bazel_version: the Bazel version string
  Returns:
    An int 3-tuple of a (major, minor, patch) version.
  """

  version = _extract_version_number(bazel_version)
  return tuple([int(n) for n in version.split(".")])


def init():
  """Prepartion work before starting the migration."""
  exit_code, stdout, _ = execute_command(["bazel", "--version"])
  eprint(stdout.strip())
  if exit_code != 0 or not stdout:
    warning("Current bazel is not a release version.")
    eprint("Please make sure you are running at least bazel 5.1.0")
  elif _parse_bazel_version(stdout.strip().split(" ")[1]) < (5, 1, 0):
    error("Current Bazel version  is older than 5.1.0")
    eprint("Please make sure you are running at least bazel 5.1.0")
    abort_migration()


  # Create MODULE.bazel file if it doesn't exist already.
  scratch_file("MODULE.bazel", [], mode="a")

  # Create WORKSPACE.bzlmod file if it doesn't exist already.
  scratch_file("WORKSPACE.bzlmod", [], mode="a")

  # Add build:bzlmod --experimental_enable_bzlmod into the .bazelrc file.
  if not grep_file(".bazelrc", "build:bzlmod --experimental_enable_bzlmod"):
    scratch_file(".bazelrc", ["",
                              "# Enable Bzlmod",
                              "build:bzlmod --experimental_enable_bzlmod"], mode="a")

  # Parse the original workspace name from the WORKSPACE file
  with open("WORKSPACE", "r") as f:
    for line in f:
      s = re.search(
          r"workspace\(name\s+=\s+[\'\"]([A-Za-z0-9_-]+)[\'\"]", line)
      if s:
        global WORKSPACE_NAME
        WORKSPACE_NAME = s.groups()[0]
        info(f"Detected original workspace name: {WORKSPACE_NAME}")
        break


def generate_resolved_file(targets):
  exit_code, _, stderr = execute_command(["bazel", "clean", "--expunge"])
  assertExitCode(exit_code, 0, "Failed to run `bazel clean --expunge`", stderr)
  bazel_nobuild_command = ["bazel", "build", "--nobuild",
                           "--experimental_repository_resolved_file=resolved_deps.py"] + targets
  bazel_sync_comand = ["bazel", "sync",
                       "--experimental_repository_resolved_file=resolved_deps.py"]
  bazel_command = bazel_sync_comand if USE_BAZEL_SYNC else bazel_nobuild_command
  exit_code, _, stderr = execute_command(bazel_command)
  assertExitCode(exit_code, 0, "Failed to run `" +
                 " ".join(bazel_command) + "`", stderr)


def load_resolved_deps(argv):
  """Generate and load the resolved file that contains external deps info."""
  if not pathlib.Path('resolved_deps.py').is_file():
    info("Generating ./resolved_deps.py file")
    generate_resolved_file(argv)
  else:
    info("Found existing ./resolved_deps.py file, if it's out of date, please delete it and rerun the script.")

  spec = importlib.util.spec_from_file_location(
      "resolved_deps", "./resolved_deps.py")
  module = importlib.util.module_from_spec(spec)
  sys.modules["resolved_deps"] = module
  spec.loader.exec_module(module)
  resolved_deps = module.resolved
  info("Found %d external repositories in the ./resolved_deps.py file." %
       len(resolved_deps))
  return resolved_deps


def abort_migration():
  info("Abort migration...")
  exit(2)


def main(argv=None):
  if argv is None:
    argv = sys.argv[1:]

  init()

  resolved_deps = load_resolved_deps(argv)

  while True:
    # Try to build with Bzlmod enabled
    bazel_command = ["bazel", "build", "--nobuild", "--config=bzlmod"] + argv
    exit_code, _, stderr = execute_command(bazel_command)
    if exit_code == 0:
      info("Congratulations! All external repositories needed for building `" +
           " ".join(argv) + "` are available with Bzlmod (and the WORKSPACE.bzlmod file)!")
      info("Things you should do next:")
      info("  - Migrate remaining dependencies in the WORKSPACE.bzlmod file to Bzlmod.")
      info("  - Run the actual build with Bzlmod enabled (with --config=bzlmod, but without --nobuild) and fix remaining build time issues.")
      break

    # 1. Detect build failure caused by unavailable repository
    repo, _ = detect_unavailable_repo_error(stderr)
    if repo:
      if address_unavailable_repo_error(repo, resolved_deps):
        continue
      else:
        abort_migration()

    # 2. Detect build failure caused by unavailable bind statements
    bind_target = detect_bind_issue(stderr)
    if bind_target:
      if address_bind_issue(bind_target, resolved_deps):
        continue
      else:
        abort_migration()

    error("Unrecognized error:\n" + stderr)
    return 1

  return 0


if __name__ == "__main__":
  sys.exit(main())
