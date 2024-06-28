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
  - Verify the checked in MODULE.bazel file matches the one in the extracted and patched source tree.
"""

import argparse
import json
import subprocess
from pathlib import Path
import shutil
import sys
import tempfile
import os
import yaml

from enum import Enum
from difflib import unified_diff
from urllib.parse import urlparse

from registry import RegistryClient
from registry import Version
from registry import download
from registry import download_file
from registry import integrity
from registry import read
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
    if not inputs:
        return []
    result = []
    for s in inputs:
        if "@" in s:
            name, version = s.split("@")
            result.append((name, version))
        else:
            result.extend(registry.get_module_versions(s))
    return result


def apply_patch(work_dir, patch_strip, patch_file):
    # Requires patch to be installed
    subprocess.run(
        ["patch", "-p%d" % patch_strip, "-f", "-l", "-i", patch_file],
        shell=False,
        check=True,
        env=os.environ,
        cwd=work_dir,
    )


def fix_line_endings(lines):
    return [line.rstrip() + "\n" for line in lines]


class BcrValidationException(Exception):
    """
    Raised whenever we should stop the validation immediately.
    """


class BcrValidator:
    def __init__(self, registry, should_fix):
        self.validation_results = []
        self.registry = registry
        # Whether the validator should try to fix the detected error.
        self.should_fix = should_fix

    def report(self, type, message):
        color = COLOR[type]
        print(f"{color}{type}{RESET}: {message}\n")
        self.validation_results.append((type, message))

    def verify_module_existence(self, module_name, version):
        """Verify the directory exists and the version is recorded in metadata.json."""
        if not self.registry.contains(module_name, version):
            self.report(BcrValidationResult.FAILED, f"{module_name}@{version} doesn't exist.")
            raise BcrValidationException("The module to be validated doesn't exist!")
        versions = self.registry.get_metadata(module_name)["versions"]
        if version not in versions:
            self.report(
                BcrValidationResult.FAILED, f"Version {version} is not recorded in {module_name}'s metadata.json file."
            )
        else:
            self.report(BcrValidationResult.GOOD, "The module exists and is recorded in metadata.json.")

    def verify_source_archive_url_match_github_repo(self, module_name, version):
        """Verify the source archive URL matches the github repo. For now, we only support github repositories check."""
        source_url = self.registry.get_source(module_name, version)["url"]
        source_repositories = self.registry.get_metadata(module_name).get("repository", [])
        matched = not source_repositories
        for source_repository in source_repositories:
            if matched:
                break
            repo_type, repo_path = source_repository.split(":")
            if repo_type == "github":
                parts = urlparse(source_url)
                matched = (
                    parts.scheme == "https"
                    and parts.netloc == "github.com"
                    and os.path.abspath(parts.path).startswith(f"/{repo_path}/")
                )
            elif repo_type == "https":
                repo = urlparse(source_repository)
                parts = urlparse(source_url)
                matched = (
                    parts.scheme == repo.scheme
                    and parts.netloc == repo.netloc
                    and os.path.abspath(parts.path).startswith(f"{repo.path}/")
                )
        if not matched:
            self.report(
                BcrValidationResult.FAILED,
                f"The source URL of {module_name}@{version} ({source_url}) doesn't match any of the module's source repositories {source_repositories}.",
            )
        else:
            self.report(BcrValidationResult.GOOD, "The source URL matches one of the source repositories.")

    def verify_source_archive_url_stability(self, module_name, version):
        """Verify source archive URL is stable"""
        source_url = self.registry.get_source(module_name, version)["url"]
        if verify_stable_archive(source_url) == UrlStability.UNSTABLE:
            self.report(
                BcrValidationResult.FAILED,
                f"{module_name}@{version} is using an unstable source url: `{source_url}`.\n"
                + "You should use a release archive URL in the format of "
                + "`https://github.com/<ORGANIZATION>/<REPO>/releases/download/<version>/<name>.tar.gz` "
                + "to ensure the archive checksum stability.\n"
                + "See https://blog.bazel.build/2023/02/15/github-archive-checksum.html for more context.",
            )
        else:
            self.report(BcrValidationResult.GOOD, "The source URL doesn't look unstable.")

    def verify_source_archive_url_integrity(self, module_name, version):
        """Verify the integrity value of the URL is correct."""
        source_url = self.registry.get_source(module_name, version)["url"]
        expected_integrity = self.registry.get_source(module_name, version)["integrity"]
        algorithm, _ = expected_integrity.split("-", 1)
        real_integrity = integrity(download(source_url), algorithm)
        if real_integrity != expected_integrity:
            self.report(
                BcrValidationResult.FAILED,
                f"{module_name}@{version}'s source archive `{source_url}` has expected integrity value "
                f"`{expected_integrity}`, but the real integrity value is `{real_integrity}`!",
            )
        else:
            self.report(BcrValidationResult.GOOD, "The source archive's integrity value matches.")

    def verify_presubmit_yml_change(self, module_name, version):
        """Verify if the presubmit.yml is the same as the previous version."""
        versions = self.registry.get_metadata(module_name)["versions"]
        versions.sort(key=Version)
        index = versions.index(version)
        if index == 0:
            self.report(
                BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW,
                f"Module version {module_name}@{version} is new, the presubmit.yml file "
                "should be reviewed by a BCR maintainer.",
            )
        elif index > 0:
            pre_version = versions[index - 1]
            previous_presubmit_yml = self.registry.get_presubmit_yml_path(module_name, pre_version)
            previous_presubmit_content = open(previous_presubmit_yml, "r").readlines()
            current_presubmit_yml = self.registry.get_presubmit_yml_path(module_name, version)
            current_presubmit_content = open(current_presubmit_yml, "r").readlines()
            diff = list(
                unified_diff(
                    previous_presubmit_content,
                    current_presubmit_content,
                    fromfile=str(previous_presubmit_yml),
                    tofile=str(current_presubmit_yml),
                )
            )
            if diff:
                self.report(
                    BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW,
                    f"The presubmit.yml file of {module_name}@{version} doesn't match its previous version "
                    f"{module_name}@{pre_version}, the following presubmit.yml file change "
                    "should be reviewed by a BCR maintainer.\n    " + "    ".join(diff),
                )
            else:
                self.report(BcrValidationResult.GOOD, "The presubmit.yml file matches the previous version.")

    def add_module_dot_bazel_patch(self, diff, module_name, version):
        """Adding a patch file for MODULE.bazel according to the diff result."""
        source = self.registry.get_source(module_name, version)
        patch_file = self.registry.get_patch_file_path(module_name, version, "module_dot_bazel.patch")
        patch_file.parent.mkdir(parents=True, exist_ok=True)
        open(patch_file, "w").writelines(diff)
        source["patch_strip"] = int(source.get("patch_strip", 0))
        patches = source.get("patches", {})
        patches["module_dot_bazel.patch"] = integrity(read(patch_file))
        source["patches"] = patches
        source_json_content = json.dumps(source, indent=4) + "\n"
        self.registry.get_source_json_path(module_name, version).write_text(source_json_content)

    def verify_module_dot_bazel(self, module_name, version):
        source = self.registry.get_source(module_name, version)
        source_url = source["url"]
        tmp_dir = Path(tempfile.mkdtemp())
        archive_file = tmp_dir.joinpath(source_url.split("/")[-1].split("?")[0])
        output_dir = tmp_dir.joinpath("source_root")
        download_file(source_url, archive_file)
        shutil.unpack_archive(str(archive_file), output_dir)

        # Apply patch files if there are any, also verify their integrity values
        source_root = output_dir.joinpath(source["strip_prefix"] if "strip_prefix" in source else "")
        if "patches" in source:
            for patch_name, expected_integrity in source["patches"].items():
                patch_file = self.registry.get_patch_file_path(module_name, version, patch_name)
                actual_integrity = integrity(read(patch_file))
                if actual_integrity != expected_integrity:
                    self.report(
                        BcrValidationResult.FAILED,
                        f"The patch file `{patch_file}` has expected integrity value `{expected_integrity}`, "
                        f"but the real integrity value is `{actual_integrity}`.",
                    )
                apply_patch(source_root, source["patch_strip"], str(patch_file.resolve()))
        if "overlay" in source:
            overlay_dir = self.registry.get_overlay_dir(module_name, version)
            for overlay_file, expected_integrity in source["overlay"].items():
                overlay_src = overlay_dir / overlay_file
                overlay_dst = source_root / overlay_file
                try:
                    overlay_dst.resolve().relative_to(source_root)
                except ValueError:
                    self.report(
                        BcrValidationResult.FAILED,
                        f"The overlay file path `{overlay_file}` must point inside the source archive.",
                    )
                    continue
                try:
                    actual_integrity = integrity(read(overlay_src))
                except FileNotFoundError:
                    self.report(BcrValidationResult.FAILED, f"The overlay file `{overlay_file}` does not exist")
                    continue
                if actual_integrity != expected_integrity:
                    self.report(
                        BcrValidationResult.FAILED,
                        f"The overlay file `{overlay_file}` has expected integrity value `{expected_integrity}`, "
                        f"but the real integrity value is `{actual_integrity}`.",
                    )
                    continue
                overlay_dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(overlay_src, overlay_dst)

        source_module_dot_bazel = source_root.joinpath("MODULE.bazel")
        if source_module_dot_bazel.exists():
            source_module_dot_bazel_content = open(source_module_dot_bazel, "r").readlines()
        else:
            source_module_dot_bazel_content = []
        bcr_module_dot_bazel_content = open(
            self.registry.get_module_dot_bazel_path(module_name, version), "r"
        ).readlines()
        source_module_dot_bazel_content = fix_line_endings(source_module_dot_bazel_content)
        bcr_module_dot_bazel_content = fix_line_endings(bcr_module_dot_bazel_content)
        file_name = "a/" * int(source.get("patch_strip", 0)) + "MODULE.bazel"
        diff = list(
            unified_diff(
                source_module_dot_bazel_content, bcr_module_dot_bazel_content, fromfile=file_name, tofile=file_name
            )
        )

        if diff:
            self.report(
                BcrValidationResult.FAILED,
                "Checked in MODULE.bazel file doesn't match the one in the extracted and patched sources.\n"
                + f"Please fix the MODULE.bazel file or you can add the following patch to {module_name}@{version}:\n"
                + "    "
                + "    ".join(diff),
            )
            if self.should_fix:
                self.add_module_dot_bazel_patch(diff, module_name, version)
        else:
            self.report(BcrValidationResult.GOOD, "Checked in MODULE.bazel matches the sources.")

        shutil.rmtree(tmp_dir)

    def check_if_bazel_version_is_set(self, tasks):
        for task_name, task_config in tasks.items():
            if "bazel" not in task_config:
                self.report(
                    BcrValidationResult.FAILED,
                    "Missing bazel version for task '%s' in the presubmit.yml file." % task_name,
                )

    def validate_presubmit_yml(self, module_name, version):
        presubmit_yml = self.registry.get_presubmit_yml_path(module_name, version)
        presubmit = yaml.safe_load(open(presubmit_yml, "r"))
        report_num_old = len(self.validation_results)
        tasks = presubmit.get("tasks", {})
        self.check_if_bazel_version_is_set(tasks)
        test_module_tasks = {}
        if "bcr_test_module" in presubmit:
            test_module_tasks = presubmit["bcr_test_module"].get("tasks", {})
            self.check_if_bazel_version_is_set(test_module_tasks)
        if not tasks and not test_module_tasks:
            self.report(BcrValidationResult.FAILED, "At least one task should be specified in the presubmit.yml file.")
        report_num_new = len(self.validation_results)
        if report_num_new == report_num_old:
            self.report(BcrValidationResult.GOOD, "The presubmit.yml file is valid.")

    def verify_module_name_conflict(self):
        """Verify no module name conflict when ignoring case sensitivity."""
        module_names = self.registry.get_all_modules()
        conflict_found = False
        module_group = {}
        for name in module_names:
            module_group.setdefault(name.lower(), []).append(name)

        for name, modules in module_group.items():
            if len(modules) > 1:
                conflict_found = True
                self.report(BcrValidationResult.FAILED, f"Module name conflict found: {', '.join(modules)}")

        if not conflict_found:
            self.report(BcrValidationResult.GOOD, "No module name conflict found.")

    def validate_module(self, module_name, version, skipped_validations):
        print_expanded_group(f"Validating {module_name}@{version}")
        self.verify_module_name_conflict()
        self.verify_module_existence(module_name, version)
        if "source_repo" not in skipped_validations:
            self.verify_source_archive_url_match_github_repo(module_name, version)
        if "url_stability" not in skipped_validations:
            self.verify_source_archive_url_stability(module_name, version)
        self.verify_source_archive_url_integrity(module_name, version)
        if "presubmit_yml" not in skipped_validations:
            self.verify_presubmit_yml_change(module_name, version)
        self.validate_presubmit_yml(module_name, version)
        self.verify_module_dot_bazel(module_name, version)

    def validate_all_metadata(self):
        print_expanded_group("Validating all metadata.json files")
        has_error = False
        for module_name in self.registry.get_all_modules():
            try:
                metadata = self.registry.get_metadata(module_name)
            except json.JSONDecodeError as e:
                self.report(BcrValidationResult.FAILED, f"Failed to load {module_name}'s metadata.json file: " + str(e))
                has_error = True
                continue

            sorted_versions = sorted(metadata["versions"], key=Version)
            if sorted_versions != metadata["versions"]:
                self.report(
                    BcrValidationResult.FAILED,
                    f"{module_name}'s metadata.json file is not sorted by version.\n "
                    f"Sorted versions: {sorted_versions}.\n "
                    f"Original versions: {metadata['versions']}",
                )
                has_error = True

            for version in metadata["versions"]:
                if not self.registry.contains(module_name, version):
                    self.report(
                        BcrValidationResult.FAILED,
                        f"{module_name}@{version} doesn't exist, "
                        f"but it's recorded in {module_name}'s metadata.json file.",
                    )
                    has_error = True
        if not has_error:
            self.report(BcrValidationResult.GOOD, "All metadata.json files are valid.")

    def getValidationReturnCode(self):
        # Calculate the overall return code
        # 0: All good
        # 1: BCR validation failed
        # 42: BCR validation passes, but some changes need BCR maintainer review before trigging follow up BCR presubmit jobs.
        result_codes = [code for code, _ in self.validation_results]
        if BcrValidationResult.FAILED in result_codes:
            return 1
        if BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW in result_codes:
            # Use a special return code to avoid conflict with other error code
            return 42
        return 0


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--registry",
        type=str,
        default=".",
        help="Specify the root path of the registry (default: the current working directory).",
    )
    parser.add_argument(
        "--check",
        type=str,
        action="append",
        help="Specify a Bazel module version you want to perform the BCR check on."
        + " (e.g. bazel_skylib@1.3.0). If no version is specified, all versions of that module are checked."
        + " This flag can be repeated to accept multiple module versions.",
    )
    parser.add_argument(
        "--check_all", action="store_true", help="Check all Bazel modules in the registry, ignore other --check flags."
    )
    parser.add_argument(
        "--check_all_metadata", action="store_true", help="Check all Bazel module metadata in the registry."
    )
    parser.add_argument(
        "--fix", action="store_true", help="Should the script try to fix the detected validation errors."
    )
    parser.add_argument(
        "--skip_validation",
        type=str,
        default=[],
        action="append",
        help='Bypass the given step for validating modules. Supported values are: "url_stability", '
        + 'to bypass the URL stability check; "presubmit_yml", to bypass the presubmit.yml check; '
        + '"source_repo", to bypass the source repo verification; '
        + "This flag can be repeated to skip multiple validations.",
    )

    args = parser.parse_args(argv)

    if not args.check_all and not args.check and not args.check_all_metadata:
        parser.print_help()
        return -1

    registry = RegistryClient(args.registry)

    # Parse what module versions we should validate
    module_versions = parse_module_versions(registry, args.check_all, args.check)
    if module_versions:
        print_expanded_group("Module versions to be validated:")
        for name, version in module_versions:
            print(f"{name}@{version}")

    # Validate given module version.
    validator = BcrValidator(registry, args.fix)
    for name, version in module_versions:
        validator.validate_module(name, version, args.skip_validation)

    if args.check_all_metadata:
        validator.validate_all_metadata()

    return validator.getValidationReturnCode()


if __name__ == "__main__":
    # Under 'bazel run' we want to run within the source folder instead of the execroot.
    if os.getenv("BUILD_WORKSPACE_DIRECTORY"):
        os.chdir(os.getenv("BUILD_WORKSPACE_DIRECTORY"))
    sys.exit(main())
