#!/usr/bin/env python3
#
# Copyright 2025 The Bazel Authors. All rights reserved.
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
import pathlib
import sys
import shutil
import os
import logging

import bcr_presubmit


def get_host_platform():
    if sys.platform == "darwin":
        return "macos"
    if sys.platform == "win32":
        return "windows"
    # Default to linux
    return "linux"


def get_task_platform(task):
    platform = task.get("platform")
    if platform.startswith("macos"):
        return "macos"
    if platform.startswith("windows"):
        return "windows"
    # Default to linux
    return "linux"


def appendFlagsToBazelrc(repo_root):
    # Refactor startup flags and common build/test flags into a .bazelrc file
    with open(os.path.join(repo_root, ".bazelrc"), "a") as f:
        f.write("common --announce_rc\n")
        f.write("common --repository_cache=\n")  # Disable repo cache to prevent it from caching BCR
        f.write("common --lockfile_mode=off\n")  # Disable lockfile to prevent it from caching BCR
        f.write("build --verbose_failures\n")


def print_build_instruction(module_name, module_version, repo_root, task_configs):
    build_targets = test_targets = bazel_version = None

    # Find the first task that matches the host platform
    host_platform = get_host_platform()
    task_name = None
    for task_id, task in task_configs["tasks"].items():
        platform = get_task_platform(task)
        if platform == host_platform:
            task_name = task.get("name", task_id)
            build_flags = task.get("build_flags", [])
            build_targets = task.get("build_targets", [])
            test_flags = task.get("test_flags", [])
            test_targets = task.get("test_targets", [])
            bazel_version = task.get("bazel")
            break

    presubmit_yml = bcr_presubmit.get_presubmit_yml(module_name, module_version)
    if not task_name:
        print("\nNo task found for the host platform: %s" % host_platform)
        print(f"Please check {presubmit_yml} on which targets to build.\n")
        return

    if not build_targets and not test_targets:
        print("\nNo build or test targets found in the task config.")
        print(f"Please check {presubmit_yml} on which targets to build.\n")
        return

    print(
        f'\nTo reproduce task "{task_name}" on {host_platform} with Bazel {bazel_version}, follow these steps (make sure Bazelisk is installed as bazel):\n'
    )

    if bazel_version:
        if host_platform == "windows":
            print(f"    set USE_BAZEL_VERSION={bazel_version}")
        else:
            print(f"    export USE_BAZEL_VERSION={bazel_version}")

    print(f"    cd {repo_root}")
    print(f"    bazel clean --expunge")

    if build_targets:
        bazel_build_command = (
            f"bazel --nosystem_rc --nohome_rc build {' '.join(build_flags)} -- {' '.join(build_targets)}"
        )
        print(f"    {bazel_build_command}")
    if test_targets:
        bazel_test_command = f"bazel --nosystem_rc --nohome_rc test {' '.join(test_flags)} -- {' '.join(test_targets)}"
        print(f"    {bazel_test_command}")
    print(f"\nMake sure to check {presubmit_yml} for additional build and test configurations.")
    print()


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s: %(message)s")

    parser = argparse.ArgumentParser(
        description="Setup repos for reproducing BCR presubmit builds locally.",
        usage="bazel run //tools:setup_presubmit_repos -- --module foo@1.2.0",
    )
    parser.add_argument("--module", required=True, help="Module name and version, e.g. foo@1.2.0")
    args = parser.parse_args()

    try:
        module_name, module_version = args.module.split("@")
    except ValueError:
        logging.error("Invalid module argument: %s. Expected format: module_name@module_version", args.module)
        return 1

    # Make sure bcr_presubmit.BCR_REPO_DIR is set to the correct directory
    #   1. BCR_REPO_DIR default to the current working directory
    #   2. If running with Bazel, BCR_REPO_DIR is set to the workspace root
    if "BUILD_WORKSPACE_DIRECTORY" in os.environ:
        bcr_presubmit.BCR_REPO_DIR = pathlib.Path(os.environ["BUILD_WORKSPACE_DIRECTORY"])
    logging.info("Testing using registry at: %s", bcr_presubmit.BCR_REPO_DIR)

    presubmit_yml = bcr_presubmit.get_presubmit_yml(module_name, module_version)
    if not presubmit_yml.exists():
        logging.error("Presubmit YAML file does not exist: %s", presubmit_yml)
        return 1

    anonymous_module_task_config = bcr_presubmit.get_anonymous_module_task_config(module_name, module_version)
    test_module_task_config = bcr_presubmit.get_test_module_task_config(module_name, module_version)

    test_root = bcr_presubmit.BCR_REPO_DIR / "temp_test_repos" / module_name / module_version

    if anonymous_module_task_config.get("tasks"):
        anonymous_module_root = test_root / "anonymous_module"
        logging.info("Creating anonymous module repo at: %s", anonymous_module_root)
        try:
            shutil.rmtree(anonymous_module_root, ignore_errors=True)
            anonymous_module_root.mkdir(exist_ok=True, parents=True)
            bcr_presubmit.create_anonymous_repo(module_name, module_version, anonymous_module_root)
            logging.info("Anonymous module repo ready at: %s", anonymous_module_root)
            appendFlagsToBazelrc(anonymous_module_root)
            print_build_instruction(module_name, module_version, anonymous_module_root, anonymous_module_task_config)
        except Exception as e:
            logging.error("Failed to create anonymous module repo: %s", e)
            raise e
    else:
        logging.info("No anonymous module task config found for %s@%s", module_name, module_version)

    if test_module_task_config.get("tasks"):
        test_module_root = test_root / "test_module"
        logging.info("Creating test module repo at: %s", test_module_root)
        try:
            shutil.rmtree(test_module_root, ignore_errors=True)
            test_module_root.mkdir(exist_ok=True, parents=True)
            test_module_root, _ = bcr_presubmit.prepare_test_module_repo(
                module_name, module_version, overwrite_bazel_version=None, root=test_module_root, suppress_log=True
            )
            logging.info("Test module repo ready at: %s", test_module_root)
            appendFlagsToBazelrc(test_module_root)
            print_build_instruction(module_name, module_version, test_module_root, test_module_task_config)
        except Exception as e:
            logging.error("Failed to create test module repo: %s", e)
            raise e
    else:
        logging.info("No test module task config found for %s@%s", module_name, module_version)


if __name__ == "__main__":
    sys.exit(main())
