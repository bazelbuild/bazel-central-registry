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

import argparse
import importlib.util
import json
import locale
import pathlib
import re
import subprocess
import sys
import tempfile

from registry import RegistryClient

# The registry client points to the bazel central registry repo
REGISTRY_CLIENT = RegistryClient(pathlib.Path(__file__).parent.parent)

COMMON_REPO_TO_MODULE_MAP = {
    "build_bazel_apple_support": "apple_support",
    "build_bazel_rules_nodejs": "rules_nodejs",
    "build_bazel_rules_swift": "rules_swift",
    "com_github_cares_cares": "c-ares",
    "com_github_gflags_gflags": "gflags",
    "com_github_grpc_grpc": "grpc",
    "com_google_absl": "abseil-cpp",
    "com_google_googletest": "googletest",
    "com_google_protobuf": "protobuf",
    "com_googlesource_code_re2": "re2",
    "io_bazel_rules_go": "rules_go",
    "io_bazel_skydoc": "stardoc",
}

LOAD_IDENTIFIER = "# -- load statements -- #"
REPO_IDENTIFIER = "# -- repo definitions -- #"
BAZEL_DEP_IDENTIFIER = "# -- bazel_dep definitions -- #"


def abort_migration():
  info("Abort migration...")
  exit(2)


def assertExitCode(exit_code, expected_exit_code, error_message, stderr):
  if exit_code != expected_exit_code:
    error(f"Command exited with {exit_code}, expected {expected_exit_code}:")
    eprint(stderr)
    abort_migration()


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
  if not yes_or_no.enable:
    return default

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
  """Write lines to a file."""
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
  PATTERNS = [
      re.compile(r"unknown repo '([A-Za-z0-9_-]+)' requested from"),
      re.compile(r"The repository '@([A-Za-z0-9_-]+)' could not be resolved"),
      re.compile(
          r"No repository visible as '@([A-Za-z0-9_-]+)' from main repository"),
      re.compile(
          r"This could either mean you have to add the '@([A-Za-z0-9_-]+)' repository"),
  ]

  for line in stderr.split("\n"):
    for p in PATTERNS:
      m = p.search(line)
      if m:
        eprint(line)
        return m.groups()[0]

  return None


def write_at_given_place(filename, new_content, identifier):
  """Write content to a file at a position marked by the identifier."""
  file_content = ""
  with open(filename, "r") as f:
    file_content = f.read()
    file_content = file_content.replace(
        identifier,
        new_content + "\n" + identifier,
        1,
    )
  with open(filename, "w") as f:
    f.write(file_content)


def add_repo_to_module_extension(repo, repo_def):
  """Introduce a repository via a module extension."""
  info(f"Introducing @{repo} via a module extension.")

  m = re.search(r'load\(\"@([\w\d-]+)\/\/', repo_def[0])
  need_separate_module_extension = m and m.group(1) != "bazel_tools"
  ext_name = f"extension_for_{m.group(1)}".replace(
      "-", "_") if need_separate_module_extension else "non_module_deps"
  ext_bzl_name = ext_name + ".bzl"

  # Generate the initial bzl file for the module extension
  if not pathlib.Path(ext_bzl_name).is_file():
    scratch_file(ext_bzl_name, [
        LOAD_IDENTIFIER,
        "",
        f"def _{ext_name}_impl(ctx):",
        REPO_IDENTIFIER,
        "",
        f"{ext_name} = module_extension(implementation = _{ext_name}_impl)"
    ])

  # Add repo definition to the module extension's bzl file
  bzl_content = open(ext_bzl_name, "r").read()
  if repo_def[0] not in bzl_content:
    write_at_given_place(ext_bzl_name, repo_def[0], LOAD_IDENTIFIER)
  write_at_given_place(
      ext_bzl_name,
      "\n".join(["  " + line.replace("\n", "\n  ") for line in repo_def[1:]]),
      REPO_IDENTIFIER,
  )

  # Add use_repo statement in the MODULE.bazel file
  use_ext = f"{ext_name} = use_extension(\"//:{ext_name}.bzl\", \"{ext_name}\")"
  module_bazel_content = open("MODULE.bazel", "r").read()
  ext_identifier = f"# End of extension `{ext_name}`"
  if use_ext not in module_bazel_content:
    scratch_file("MODULE.bazel", ["", use_ext, ext_identifier], mode="a")
  write_at_given_place(
      "MODULE.bazel", f"use_repo({ext_name}, \"{repo}\")", ext_identifier)


def address_unavailable_repo_error(repo, resolved_deps, workspace_name):
  error(f"@{repo} is not visible in the Bzlmod build.")

  # Check if it's the original main repo name
  if repo == workspace_name:
    error(
        f"Please remove the usages of referring your own repo via `@{repo}//`, targets should be referenced directly with `//`. ")
    eprint("If it's used in a macro, you can use `Label(\"//foo/bar\")` to make sure it always points to your repo no matter where the macro is used.")
    eprint("You can temporarily work around this by adding `repo_name` attribute to the `module` directive in your MODULE.bazel file.")
    abort_migration()

  # Print the repo definition in the original WORKSPACE file
  repo_def = []
  for dep in resolved_deps:
    if dep["original_attributes"]["name"] == repo:
      repo_def = print_repo_definition(dep)
      break
  if not repo_def:
    error(
        f"Repository definition for {repo} isn't found in ./resolved_deps.py file, please add `--force/-f` flag to force update it.")
    abort_migration()

  # Check if a module is already available in the registry.
  found_module = None
  for module_name in REGISTRY_CLIENT.get_all_modules():
    # Check if there is matching module name or a well known repo name for a matching module.
    if repo == module_name or COMMON_REPO_TO_MODULE_MAP.get(repo) == module_name:
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

    if yes_or_no("Do you wish to add the bazel_dep definition to the MODULE.bazel file?", True):
      info(f"Introducing @{repo} as a Bazel module.")
      write_at_given_place("MODULE.bazel", bazel_dep_line,
                           BAZEL_DEP_IDENTIFIER)
      return True
  else:
    info(f"{repo} isn't found in the registry.")

  # ask user if the dependency should be introduced via module extension if it looks like a starlark repository rule.
  if repo_def[0].startswith("load(") and yes_or_no("Do you wish to introduce the repository with a module extension?", True):
    add_repo_to_module_extension(repo, repo_def)
  # Ask user if this dep should be added to the WORKSPACE.bzlmod for later migration.
  elif yes_or_no("Do you wish to add the repo definition to WORKSPACE.bzlmod for later migration?", True):
    repo_def = ["", "# TODO: Migrated to Bzlmod"] + repo_def
    info(f"Introducing @{repo} in WORKSPACE.bzlmod file.")
    scratch_file("WORKSPACE.bzlmod", repo_def, mode="a")
  else:
    info("Please manually add this dependency ...")
    abort_migration()
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
      f"A bind target detected: {bind_target}! `bind` is already deprecated, you should reference the actual target directly instead of using //external:<target>.")

  name = bind_target.split(":")[1]
  bind_def = None
  for dep in resolved_repos:
    if dep["original_rule_class"] == "bind" and dep["original_attributes"]["name"] == name:
      bind_def = print_repo_definition(dep)
      break

  if bind_def:
    bind_def = ["", "# TODO: Remove the following bind usage"] + bind_def
    if yes_or_no("Do you wish to add the bind definition to WORKSPACE.bzlmod for later migration?", True):
      info(f"Adding bind statement for {bind_target} in WORKSPACE.bzlmod")
      scratch_file("WORKSPACE.bzlmod", bind_def, mode="a")
      return True
  else:
    warning(
        f"Bind definition for {bind_target} isn't found in ./resolved_deps.py file, please fix manually. "
        + "You can get more verbose info by rerun the script with --sync/-s and --force/-f flags "
        + "(but it might take a long time and could fail).")
    abort_migration()


def extract_version_number(bazel_version):
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


def parse_bazel_version(bazel_version):
  """Parses a version string into a 3-tuple of ints
  int tuples can be compared directly using binary operators (<, >).
  Args:
    bazel_version: the Bazel version string
  Returns:
    An int 3-tuple of a (major, minor, patch) version.
  """

  version = extract_version_number(bazel_version)
  return tuple([int(n) for n in version.split(".")])


def prepare_migration():
  """Preparation work before starting the migration."""
  exit_code, stdout, _ = execute_command(["bazel", "--version"])
  eprint(stdout.strip())
  if exit_code != 0 or not stdout:
    warning("Current bazel is not a release version, please make sure you are running at least bazel 6.0.0")
  elif parse_bazel_version(stdout.strip().split(" ")[1]) < (6, 0, 0):
    error("Current Bazel version is older than 6.0.0, please upgrade your Bazel to at least 6.0.0. "
          + "You can download Bazelisk from https://github.com/bazelbuild/bazelisk/releases and set env var USE_BAZEL_VERSION=6.0.0.")
    abort_migration()

  # Parse the original workspace name from the WORKSPACE file
  workspace_name = "main"
  with open("WORKSPACE", "r") as f:
    for line in f:
      s = re.search(
          r"workspace\(name\s+=\s+[\'\"]([A-Za-z0-9_-]+)[\'\"]", line)
      if s:
        workspace_name = s.groups()[0]
        info(f"Detected original workspace name: {workspace_name}")

  # Create MODULE.bazel file if it doesn't exist already.
  if not pathlib.Path("MODULE.bazel").is_file():
    scratch_file("MODULE.bazel", [
                 f"module(name = \"{workspace_name}\", version=\"\")", "", BAZEL_DEP_IDENTIFIER])
  module_bazel_content = open("MODULE.bazel", "r").read()
  if BAZEL_DEP_IDENTIFIER not in module_bazel_content:
    scratch_file("MODULE.bazel", ["", BAZEL_DEP_IDENTIFIER], mode="a")

  # Create WORKSPACE.bzlmod file if it doesn't exist already.
  scratch_file("WORKSPACE.bzlmod", [], mode="a")

  return workspace_name


def generate_resolved_file(targets, use_bazel_sync):
  exit_code, _, stderr = execute_command(["bazel", "clean", "--expunge"])
  assertExitCode(exit_code, 0, "Failed to run `bazel clean --expunge`", stderr)
  bazel_nobuild_command = ["bazel", "build", "--nobuild",
                           "--experimental_repository_resolved_file=resolved_deps.py"] + targets
  bazel_sync_comand = ["bazel", "sync",
                       "--experimental_repository_resolved_file=resolved_deps.py"]
  bazel_command = bazel_sync_comand if use_bazel_sync else bazel_nobuild_command
  exit_code, _, stderr = execute_command(bazel_command)
  assertExitCode(exit_code, 0, "Failed to run `" +
                 " ".join(bazel_command) + "`", stderr)


def load_resolved_deps(targets, use_bazel_sync, force):
  """Generate and load the resolved file that contains external deps info."""
  if not pathlib.Path('resolved_deps.py').is_file() or force:
    info("Generating ./resolved_deps.py file")
    generate_resolved_file(targets, use_bazel_sync)
  else:
    info("Found existing ./resolved_deps.py file, if it's out of date, please add `--force/-f` flag to force update it.")

  spec = importlib.util.spec_from_file_location(
      "resolved_deps", "./resolved_deps.py")
  module = importlib.util.module_from_spec(spec)
  sys.modules["resolved_deps"] = module
  spec.loader.exec_module(module)
  resolved_deps = module.resolved
  info("Found %d external repositories in the ./resolved_deps.py file." %
       len(resolved_deps))
  return resolved_deps


def main(argv=None):
  if argv is None:
    argv = sys.argv[1:]

  parser = argparse.ArgumentParser(
      prog="migrate_to_bzlmod",
      description="A helper script for migrating your external dependencies from WORKSPACE to Bzlmod. "
      + "For given targets, it first tries to generate a list of external dependencies for building your targets, "
      + "then tries to detect and add missing dependencies in the Bzlmod build. "
      + "You may still need to fix some problems manually.",
      epilog="Example usage: change into your project directory and run `<path to BCR repo>/tools/migrate_to_bzlmod.py --target //foo:bar`")
  parser.add_argument(
      "-s",
      "--sync",
      action="store_true",
      help="use `bazel sync` instead of `bazel build --nobuild` to generate the resolved dependencies. "
      + "`bazel build --nobuild` only fetches dependencies needed for building specified targets, "
      + "while `bazel sync` resolves and fetches all dependencies defined in your WORKSPACE file, "
      + "including bind statements and execution platform & toolchain registrations.")
  parser.add_argument(
      "-f",
      "--force",
      action="store_true",
      help="ignore previously generated resolved dependencies.")
  parser.add_argument(
      "-i",
      "--interactive",
      action="store_true",
      help="ask the user interactively on what to do.")
  parser.add_argument(
      "-t",
      "--target",
      type=str,
      action="append",
      help="specify the targets you want to migrate. This flag is repeatable, and the targets are accumulated.")

  args = parser.parse_args(argv)

  if not args.target:
    parser.print_help()
    return 1

  workspace_name = prepare_migration()

  resolved_deps = load_resolved_deps(args.target, args.sync, args.force)

  yes_or_no.enable = args.interactive

  while True:
    # Try to build with Bzlmod enabled
    targets = args.target
    bazel_command = ["bazel", "build",
                     "--nobuild", "--enable_bzlmod"] + targets
    exit_code, _, stderr = execute_command(bazel_command)
    if exit_code == 0:
      info("Congratulations! All external repositories needed for building `" +
           " ".join(targets) + "` are available with Bzlmod (and the WORKSPACE.bzlmod file)!")
      info("Things you should do next:")
      info("  - Migrate remaining dependencies in the WORKSPACE.bzlmod file to Bzlmod.")
      info("  - Run the actual build with Bzlmod enabled (with --enable_bzlmod, but without --nobuild) and fix remaining build time issues.")
      break

    # 1. Detect build failure caused by unavailable repository
    repo = detect_unavailable_repo_error(stderr)
    if repo:
      if address_unavailable_repo_error(repo, resolved_deps, workspace_name):
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

    error("Unrecognized error, please fix manually:\n" + stderr)
    return 1

  return 0


if __name__ == "__main__":
  sys.exit(main())
