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
  - Verify attestations (SLSA provenance / VSA) referenced by attestations.json (if it exists).
"""

import argparse
import ast
import json
import os
import re
import requests
import shutil
import subprocess
import sys
import tempfile
import yaml

from difflib import unified_diff
from enum import Enum
from pathlib import Path
from urllib.parse import urlparse

import attestations as attestations_lib
import slsa

from registry import RegistryClient
from registry import UpstreamRegistry
from registry import Version
from registry import download
from registry import download_file
from registry import integrity
from registry import integrity_for_comparison
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

UPSTREAM_MODULES_DIR_URL = "https://bcr.bazel.build/modules"

DEFAULT_SLSA_VERIFIER_VERSION = "v2.7.1"

ATTESTATIONS_DOCS_URL = "https://github.com/bazelbuild/bazel-central-registry/blob/main/docs/attestations.md"

GITHUB_REPO_RE = re.compile(r"^github:([^/]+/[^/]+)$")
GITHUB_URL_RE = re.compile(r"^https://github.com/([^/]+/[^/]+)")

# Global cache for GitHub user IDs
GITHUB_USER_ID_CACHE = {}


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
        ["patch", "--strip", str(patch_strip), "--force", "--fuzz", "0", "--ignore-whitespace", "--input", patch_file],
        shell=False,
        check=True,
        env=os.environ,
        cwd=work_dir,
    )


def run_git(*args):
    # Requires git to be installed
    subprocess.run(
        ["git", *args],
        shell=False,
        check=True,
        env=os.environ,
    )


def extract_reference(repo_path, path):
    """
    Extracts the reference from a path matching the pattern /<repo_path>/archive/<ref>.zip or /<repo_path>/archive/<ref>.tar.gz

    Args:
        repo_path: The repository path.
        path: The path to extract the reference from.

    Returns:
        The reference if found, otherwise None.
    """
    pattern = rf"^/{re.escape(repo_path)}/archive/(.+)\.(zip|tar\.gz)$"
    match = re.search(pattern, path)
    if match:
        return match.group(1)
    return None


def is_ref_in_original_repo(repo_path, reference) -> bool:
    """
    Checks if the given reference is truly part of the original GitHub repository's history.

    Uses the unofficial '/latest-commit/<REF>' endpoint, which returns JSON containing "isSpoofed".

    Args:
        repo_path: The repository path.
        reference: The reference to check

    Returns:
        True if the reference is found AND not spoofed; False otherwise
    """

    # Make sure the reference is not a pull request
    # e.g. refs/pull/1234/head
    if re.match(r"^pull/\d+/head$", reference):
        return False

    url = f"https://github.com/{repo_path}/latest-commit/{reference}"
    headers = {"Accept": "application/json"}

    try:
        response = requests.get(url, headers=headers)
    except requests.RequestException:
        raise BcrValidationException(f"Failed to check if reference is from the original repository via {url}")

    if not response.status_code == 200:
        # reference doesn't exist at all
        return False

    data = response.json()
    if "isSpoofed" not in data:
        raise BcrValidationException(f"Missing 'isSpoofed' attribute in response from {url}: {data}")

    return not data.get("isSpoofed")


def check_github_url(repo_path, source_url):
    parts = urlparse(source_url)
    # Avoid potential path manipulations with "../"
    normalized_path = os.path.abspath(parts.path)

    # If the URL doesn't start with https://github.com/<repo_path>, return False
    if parts.scheme != "https" or parts.netloc != "github.com" or not normalized_path.startswith(f"/{repo_path}/"):
        return False

    # Allow paths under /<repo_path>/releases/download
    if normalized_path.startswith(f"/{repo_path}/releases/download/"):
        return True

    # Otherwise, the source archive must match /<repo_path>/archive/<reference>.<extension>
    # And we check if the reference does come from the original repository.
    reference = extract_reference(repo_path, normalized_path)
    return reference and is_ref_in_original_repo(repo_path, reference)


def get_github_user_id(github_username):
    """
    Get the GitHub user ID for a given GitHub username, with caching.

    Args:
        github_username: The GitHub username to look up.

    Returns:
        The GitHub user ID if found, otherwise None.
    """
    if github_username in GITHUB_USER_ID_CACHE:
        return GITHUB_USER_ID_CACHE[github_username]

    url = f"https://api.github.com/users/{github_username}"
    headers = {}
    github_token = os.getenv("GITHUB_TOKEN")
    if github_token:
        headers["Authorization"] = f"token {github_token}"
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        user_id = response.json().get("id")
        GITHUB_USER_ID_CACHE[github_username] = user_id
        return user_id
    raise requests.HTTPError(f"unexpected {response.status_code} status code from {url}", response=response)


def is_valid_bazel_compatibility_for_overlay(bazel_compatibility):
    """
    Returns whether the bazel_compatibility is valid for an overlay.
    See: https://bazel.build/rules/lib/globals/module#module

    Args:
        bazel_compatibility: List of bazel compatibility strings.

    Returns:
        Boolean indicating compatibility with source overlays.
    """
    if not bazel_compatibility:
        return False
    for v in bazel_compatibility:
        m = re.fullmatch(r"^([><-]=?)(\d+\.\d+\.\d+)$", v)
        if not m or m.group(1) == "-":
            continue  # Skip - versions
        version = tuple(int(i) for i in m.group(2).split("."))
        if m.group(1) == ">":
            if version > (7, 2, 0):
                return True
        elif m.group(1) == ">=":
            if version >= (7, 2, 1):
                return True
    return False


class BcrValidationException(Exception):
    """
    Raised whenever we should stop the validation immediately.
    """


class BcrValidator:
    def __init__(self, registry, upstream, should_fix, slsa_verifier_version=DEFAULT_SLSA_VERIFIER_VERSION):
        self.validation_results = []
        self.registry = registry
        self.upstream = upstream
        # Whether the validator should try to fix the detected error.
        self.should_fix = should_fix
        self._verifier = slsa.Verifier(slsa_verifier_version, tempfile.mkdtemp())

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
                BcrValidationResult.FAILED,
                f"Version {version} is not recorded in {module_name}'s metadata.json file.",
            )
        else:
            self.report(
                BcrValidationResult.GOOD,
                "The module exists and is recorded in metadata.json.",
            )

    def verify_source_archive_url_match_github_repo(self, module_name, version):
        """Verify the source archive URL matches the github repo. For now, we only support github repositories check."""
        source = self.registry.get_source(module_name, version)
        if source.get("type", None) == "git_repository":
            source_url = source["remote"]
            # Preprocess the git URL to make the comparison easier.
            if source_url.startswith("git@"):
                source_url = source_url.removeprefix("git@")
                source_netloc, source_parts = source_url.split(":")
                source_url = "https://" + source_netloc + "/" + source_parts
            if source_url.endswith(".git"):
                source_url = source_url.removesuffix(".git")
            # Make the commit look like a GitHub archive to unify the
            # rest of this check. For non-GitHub repositories, the extra
            # trailing parts are ignored.
            commit = source["commit"]
            source_url = source_url.rstrip("/")
            source_url = f"{source_url}/archive/{commit}.zip"
        else:
            source_url = source["url"]
        source_repositories = self.registry.get_metadata(module_name).get("repository", [])
        matched = not source_repositories
        for source_repository in source_repositories:
            if matched:
                break
            repo_type, repo_path = source_repository.split(":")
            if repo_type == "github":
                matched = check_github_url(repo_path, source_url)
            elif repo_type == "https":
                repo = urlparse(source_repository)
                parts = urlparse(source_url)
                expected_path = repo.path
                if not expected_path.endswith("/"):
                    expected_path += "/"
                matched = (
                    parts.scheme == repo.scheme
                    and parts.netloc == repo.netloc
                    and os.path.abspath(parts.path).startswith(expected_path)
                )
        if not matched:
            self.report(
                BcrValidationResult.FAILED,
                f"The source URL of {module_name}@{version} ({source_url}) doesn't match any of the module's source repositories {source_repositories}.\n"
                + "If it's a GitHub URL, only the following forms are allowed:\n"
                + "  1) https://github.com/<OWNER>/<REPO>/releases/download/... (Recommended)\n"
                + "  2) https://github.com/<OWNER>/<REPO>/archive/<REF>.(tar.gz|zip) where REF must come from the original repository",
            )
        else:
            self.report(
                BcrValidationResult.GOOD,
                "The source URL matches one of the source repositories.",
            )

    def verify_source_archive_url_stability(self, module_name, version):
        """Verify source archive URL is stable"""
        if self.registry.get_source(module_name, version).get("type", None) == "git_repository":
            return
        source_url = self.registry.get_source(module_name, version)["url"]
        if verify_stable_archive(source_url) == UrlStability.UNSTABLE:
            self.report(
                BcrValidationResult.FAILED,
                f"{module_name}@{version} is using an unstable source url: `{source_url}`.\n"
                + "If at all possible, you should use a release archive URL in the format of "
                + "`https://github.com/<ORGANIZATION>/<REPO>/releases/download/<version>/<name>.tar.gz` "
                + "to ensure the archive checksum stability.\n"
                + "See https://blog.bazel.build/2023/02/15/github-archive-checksum.html for more context.\n"
                + "If no release archives are available, please add a comment to your BCR PR with the text\n"
                + "    @bazel-io skip_check unstable_url\n"
                + "and this check will be skipped.",
            )
        else:
            self.report(BcrValidationResult.GOOD, "The source URL doesn't look unstable.")

    def verify_source_archive_url_integrity(self, module_name, version):
        """Verify the integrity value of the URL and mirror URLs is correct."""
        source = self.registry.get_source(module_name, version)
        if source.get("type", None) == "git_repository":
            return

        expected_integrity = source["integrity"]
        urls_to_check = [(source["url"], "main source archive URL")]

        mirror_urls = source.get("mirror_urls", [])
        for i, mirror_url in enumerate(mirror_urls):
            urls_to_check.append((mirror_url, f"mirror URL #{i + 1}"))

        all_good = True
        for url, description in urls_to_check:
            try:
                real_integrity = integrity_for_comparison(download(url), expected_integrity)
                if real_integrity != expected_integrity:
                    self.report(
                        BcrValidationResult.FAILED,
                        f"{module_name}@{version}'s {description} `{url}` has expected integrity value "
                        f"`{expected_integrity}`, but the real integrity value is `{real_integrity}`!",
                    )
                    all_good = False
            except Exception as e:
                self.report(
                    BcrValidationResult.FAILED,
                    f"Failed to download or verify integrity for {description} `{url}` of {module_name}@{version}: {e}",
                )
                all_good = False

        if all_good:
            self.report(
                BcrValidationResult.GOOD,
                "The source archive's integrity value matches all provided URLs.",
            )

    def verify_git_repo_source_stability(self, module_name, version):
        """Verify git repositories are specified in a stable way."""
        if self.registry.get_source(module_name, version).get("type", None) != "git_repository":
            return

        # There's a handful of failure modes here, don't fail fast.
        error_encountered = False
        if self.registry.get_source(module_name, version).get("branch", None):
            self.report(
                BcrValidationResult.FAILED,
                f"{module_name}@{version}'s source is a git_repository that is trying to track "
                "a branch. Please use a specific commit instead, as branches are not stable sources.",
            )
            error_encountered = True
        if self.registry.get_source(module_name, version).get("tag", None):
            self.report(
                BcrValidationResult.FAILED,
                f"{module_name}@{version}'s source is a git_repository that is trying to track "
                "a tag. Please use a specific commit instead, as tags are not stable sources.",
            )
            error_encountered = True
        commit = self.registry.get_source(module_name, version)["commit"]
        try:
            commit_hash_bytes = bytes.fromhex(commit)
            if len(commit_hash_bytes) != 20:
                self.report(
                    BcrValidationResult.FAILED,
                    f"{module_name}@{version}'s git_repository commit hash is an unexpected length.",
                )
        except ValueError:
            self.report(
                BcrValidationResult.FAILED,
                f"{module_name}@{version}'s source is a git_repository with an invalid commit hash format.",
            )
            error_encountered = True

        if not error_encountered:
            self.report(BcrValidationResult.GOOD, "The git_repository appears stable.")

    def verify_presubmit_yml_change(self, module_name, version):
        """Verify if the presubmit.yml is the same as the previous version."""
        latest_snapshot = self.upstream.get_latest_module_version(module_name)
        if not latest_snapshot:
            self.report(
                BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW,
                f"Module version {module_name}@{version} is new, the presubmit.yml file "
                "should be reviewed by a BCR maintainer.",
            )
        else:
            previous_presubmit_content = latest_snapshot.presubmit_yml_lines()
            current_presubmit_yml = self.registry.get_presubmit_yml_path(module_name, version)
            current_presubmit_content = open(current_presubmit_yml, "r").readlines()
            diff = list(
                unified_diff(
                    previous_presubmit_content,
                    current_presubmit_content,
                    fromfile="HEAD",
                    tofile=str(current_presubmit_yml),
                )
            )
            if diff:
                self.report(
                    BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW,
                    f"The presubmit.yml file of {module_name}@{version} doesn't match its previous version "
                    f"{module_name}@{latest_snapshot.version}, the following presubmit.yml file change "
                    "should be reviewed by a BCR maintainer.\n    " + "    ".join(diff),
                )
            else:
                self.report(
                    BcrValidationResult.GOOD,
                    "The presubmit.yml file matches the previous version.",
                )

    def _download_source_archive(self, source, output_dir):
        source_url = source["url"]
        tmp_dir = Path(tempfile.mkdtemp())
        archive_file = tmp_dir.joinpath(source_url.split("/")[-1].split("?")[0])
        download_file(source_url, archive_file)
        # Use archive_type from source.json if specified, otherwise let shutil guess from filename
        # https://bazel.build/rules/lib/repo/http#http_archive-type
        # https://docs.python.org/3/library/shutil.html#shutil.unpack_archive
        format = {
            "tar.gz": "gztar",
            "tgz": "gztar",
            "tar.bz2": "bztar",
            "tar.xz": "xztar",
            "tar": "tar",
            "zip": "zip",
            "jar": "zip",
            "war": "zip",
            "aar": "zip",
        }.get(source.get("archive_type"))
        shutil.unpack_archive(str(archive_file), output_dir, format=format)

    def _download_git_repo(self, source, output_dir):
        run_git("clone", "--depth=1", source["remote"], output_dir)
        run_git("-C", output_dir, "fetch", "--depth=1", "origin", source["commit"])
        run_git("-C", output_dir, "checkout", source["commit"])

    @staticmethod
    def extract_attribute_from_module(module_dot_bazel_file, attribute, default=None):
        """Extract the value of the given attribute from `module()` call in the MODULE.bazel file content"""
        with open(module_dot_bazel_file, "r") as file:
            tree = ast.parse(file.read(), filename=module_dot_bazel_file)
            for node in tree.body:
                if (
                    isinstance(node, ast.Expr)
                    and isinstance(node.value, ast.Call)
                    and isinstance(node.value.func, ast.Name)
                    and node.value.func.id == "module"
                ):
                    for k in node.value.keywords:
                        if k.arg == attribute:
                            if isinstance(k.value, ast.Constant):
                                return k.value.value
                            if isinstance(k.value, ast.List):
                                return [v.value for v in k.value.elts if isinstance(v, ast.Constant)]
                    return default

    def verify_module_dot_bazel(self, module_name, version, check_compatibility_level=True):
        source = self.registry.get_source(module_name, version)
        tmp_dir = Path(tempfile.mkdtemp())
        output_dir = tmp_dir.joinpath("source_root")
        source_type = source.get("type", "archive")
        if source_type == "archive":
            self._download_source_archive(source, output_dir)
        elif source_type == "git_repository":
            self._download_git_repo(source, output_dir)
        else:
            raise BcrValidationException("Unsupported repository type")

        module_file = self.registry.get_module_dot_bazel_path(module_name, version)
        if module_file.is_symlink():
            self.report(BcrValidationResult.FAILED, f"{module_file} must not be a symlink.")

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
                if patch_file.is_symlink():
                    self.report(
                        BcrValidationResult.FAILED,
                        f"The patch file `{patch_name}` is a symlink to `{patch_file.readlink()}`, "
                        "which is not allowed because https://raw.githubusercontent.com/ will not follow it.",
                    )
                apply_patch(source_root, source["patch_strip"], str(patch_file.resolve()))
        if "overlay" in source:
            overlay_dir = self.registry.get_overlay_dir(module_name, version)
            for overlay_file, expected_integrity in source["overlay"].items():
                overlay_src = overlay_dir / overlay_file
                if overlay_src.is_symlink():
                    self.report(
                        BcrValidationResult.FAILED,
                        f"The overlay file `{overlay_file}` is a symlink to `{overlay_src.readlink()}`, "
                        "which is not allowed because https://raw.githubusercontent.com/ will not follow it.",
                    )
                overlay_dst = source_root / overlay_file
                try:
                    overlay_dst.resolve().relative_to(source_root.resolve())
                except ValueError as e:
                    self.report(
                        BcrValidationResult.FAILED,
                        f"The overlay file path `{overlay_file}` must point inside the source archive.\n {e}",
                    )
                    continue
                try:
                    actual_integrity = integrity(read(overlay_src))
                except FileNotFoundError:
                    self.report(
                        BcrValidationResult.FAILED,
                        f"The overlay file `{overlay_file}` does not exist",
                    )
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

        bcr_module_dot_bazel = self.registry.get_module_dot_bazel_path(module_name, version)

        # Check the version in MODULE.bazel matches the version in directory name
        version_in_module_dot_bazel = BcrValidator.extract_attribute_from_module(bcr_module_dot_bazel, "version")
        if version_in_module_dot_bazel != version:
            self.report(
                BcrValidationResult.FAILED,
                "Checked in MODULE.bazel version does not match the version of the module directory added.",
            )

        # Check the compatibility_level in MODULE.bazel is monotonically increasing. Also cautiously fail if
        # it doesn't match the previous version's compatibility_level. Both checks are skippable.
        if check_compatibility_level:
            versions = self.registry.get_metadata(module_name)["versions"]
            versions.sort(key=Version)
            index = versions.index(version)
            current_compatibility_level = BcrValidator.extract_attribute_from_module(
                bcr_module_dot_bazel, "compatibility_level", 0
            )
            if index < len(versions) - 1:
                next_version = versions[index + 1]
                next_module_dot_bazel = self.registry.get_module_dot_bazel_path(module_name, next_version)
                next_compatibility_level = BcrValidator.extract_attribute_from_module(
                    next_module_dot_bazel, "compatibility_level", 0
                )
                if current_compatibility_level > next_compatibility_level:
                    self.report(
                        BcrValidationResult.FAILED,
                        f"The new module version {version} has a higher compatibility level than the next version {next_version} ({current_compatibility_level} > {next_compatibility_level}).\n"
                        + "If this is intentional, please comment on your PR `@bazel-io skip_check compatibility_level`\n"
                        + "Learn more about when to increase the compatibility level at https://bazel.build/external/faq#incrementing-compatibility-level",
                    )
            if index > 0:
                # Find the most recent non-yanked version before the current one
                metadata = self.registry.get_metadata(module_name)
                yanked_versions = metadata.get("yanked_versions", {})
                previous_version = None

                for i in range(index - 1, -1, -1):
                    candidate_version = versions[i]
                    if candidate_version not in yanked_versions:
                        previous_version = candidate_version
                        break

                if previous_version is not None:
                    previous_module_dot_bazel = self.registry.get_module_dot_bazel_path(module_name, previous_version)
                    previous_compatibility_level = BcrValidator.extract_attribute_from_module(
                        previous_module_dot_bazel, "compatibility_level", 0
                    )
                    if current_compatibility_level != previous_compatibility_level:
                        self.report(
                            BcrValidationResult.FAILED,
                            f"The compatibility_level in the new module version ({current_compatibility_level}) doesn't match the previous version ({previous_compatibility_level}).\n"
                            + "If this is intentional, please comment on your PR `@bazel-io skip_check compatibility_level`\n"
                            + "Learn more about when to increase the compatibility level at https://bazel.build/external/faq#incrementing-compatibility-level",
                        )

        # Check that bazel_compatability is sufficient when using "overlay"
        if "overlay" in source:
            current_bazel_compatibility = BcrValidator.extract_attribute_from_module(
                bcr_module_dot_bazel, "bazel_compatibility", []
            )
            if not is_valid_bazel_compatibility_for_overlay(current_bazel_compatibility):
                self.report(
                    BcrValidationResult.FAILED,
                    "When using overlay files the module must set `bazel_compatibility` constraints to "
                    f"at least `['>=7.2.1']`, got {current_bazel_compatibility}. ",
                )

        shutil.rmtree(tmp_dir)

    def check_if_bazel_version_is_set(self, tasks):
        for task_name, task_config in tasks.items():
            if "bazel" not in task_config:
                self.report(
                    BcrValidationResult.FAILED,
                    "Missing bazel version for task '%s' in the presubmit.yml file." % task_name,
                )

    def validate_presubmit_tasks(self, module_name, version):
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
            self.report(
                BcrValidationResult.FAILED,
                "At least one task should be specified in the presubmit.yml file.",
            )
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
                self.report(
                    BcrValidationResult.FAILED,
                    f"Module name conflict found: {', '.join(modules)}",
                )

        if not conflict_found:
            self.report(BcrValidationResult.GOOD, "No module name conflict found.")

    def verify_no_symlinks(self):
        """Check there is no symlink under modules/ dir"""
        for dirpath, dirnames, filenames in os.walk(self.registry.root / "modules"):
            for name in dirnames + filenames:
                full_path = os.path.join(dirpath, name)
                if os.path.islink(full_path):
                    self.report(
                        BcrValidationResult.FAILED,
                        f"Symlink is not allowed: {full_path}",
                    )

    def validate_module(self, module_name, version, skipped_validations):
        print_expanded_group(f"Validating {module_name}@{version}")
        self.verify_module_existence(module_name, version)
        self.verify_git_repo_source_stability(module_name, version)
        if "source_repo" not in skipped_validations:
            self.verify_source_archive_url_match_github_repo(module_name, version)
        if "url_stability" not in skipped_validations:
            self.verify_source_archive_url_stability(module_name, version)
        self.verify_source_archive_url_integrity(module_name, version)
        if "presubmit_yml" not in skipped_validations:
            self.verify_presubmit_yml_change(module_name, version)
        if "presubmit_task" not in skipped_validations:
            self.validate_presubmit_tasks(module_name, version)
        self.verify_module_dot_bazel(module_name, version, "compatibility_level" not in skipped_validations)
        if "attestations" not in skipped_validations:
            self.verify_attestations(module_name, version)

    def validate_metadata(self, modules):
        print_expanded_group(f"Validating metadata.json files for {modules}")
        for module_name in modules:
            self.verify_metadata_json(module_name)

    def verify_metadata_json(self, module_name):
        """Verify the metadata.json file is valid."""
        try:
            metadata = self.registry.get_metadata(module_name)
        except json.JSONDecodeError as e:
            self.report(
                BcrValidationResult.FAILED,
                f"Failed to load {module_name}'s metadata.json file: " + str(e),
            )
            return

        sorted_versions = sorted(metadata["versions"], key=Version)
        if sorted_versions != metadata["versions"]:
            self.report(
                BcrValidationResult.FAILED,
                f"{module_name}'s metadata.json file is not sorted by version.\n "
                f"Sorted versions: {sorted_versions}.\n "
                f"Original versions: {metadata['versions']}",
            )

        for version in metadata["versions"]:
            if not self.registry.contains(module_name, version):
                self.report(
                    BcrValidationResult.FAILED,
                    f"{module_name}@{version} doesn't exist, but it's recorded in {module_name}'s metadata.json file.",
                )

        latest_version = metadata["versions"][-1]
        if not metadata.get("deprecated") and latest_version in metadata.get("yanked_versions", {}):
            self.report(
                BcrValidationResult.FAILED,
                f"The latest version ({latest_version}) of {module_name} should not be yanked, "
                f"please make sure a newer version is available before yanking it.",
            )

        maintainers = metadata.get("maintainers", [])
        for maintainer in maintainers:
            if "github" in maintainer:
                github_username = maintainer["github"]
                print("checking github user id for %s" % github_username)
                try:
                    github_user_id = get_github_user_id(github_username)
                except Exception as e:
                    raise BcrValidationException(
                        f"Failed to get GitHub user ID for {github_username}. Please check the username."
                    ) from e
                if github_user_id != maintainer.get("github_user_id"):
                    self.report(
                        BcrValidationResult.FAILED,
                        f"{module_name}'s metadata.json file has an invalid GitHub user ID for {github_username}\n"
                        + f'Please add `"github_user_id": {github_user_id}` to the maintainer entry by running `bazel run //tools:bcr_validation -- --check_metadata={module_name} --fix`.',
                    )
                    if self.should_fix:
                        maintainer["github_user_id"] = github_user_id
                        self.registry.get_metadata_path(module_name).write_text(json.dumps(metadata, indent=4) + "\n")
                else:
                    self.report(
                        BcrValidationResult.GOOD,
                        f"{module_name}'s metadata.json file has a valid GitHub user ID for {github_username}",
                    )

    def verify_attestations(self, module_name, version):
        print_expanded_group("Verifying attestations")
        head_snapshot = self.upstream.get_latest_module_version(module_name)
        head_attestations_json = head_snapshot.attestations() if head_snapshot else None

        attestations_json = self.registry.get_attestations(module_name, version)
        if not attestations_json:
            if head_attestations_json:  # Prevent regressions.
                self.report(
                    BcrValidationResult.FAILED,
                    f"{module_name}@{version}: No attestations.json file even though "
                    f"{module_name}@{head_snapshot.version} has one.",
                )
            else:
                # TODO: Turn this into an error after the migration period
                self.report(BcrValidationResult.GOOD, f"{module_name}@{version}: No attestations to check.")

            return

        try:
            attestations = attestations_lib.parse_file(attestations_json, module_name, version, self.registry)
        except attestations_lib.Error as ex:
            self.report(
                BcrValidationResult.FAILED,
                (
                    f"{module_name}@{version}: Encountered an error in attestations.json:"
                    f" {ex} Please follow {ATTESTATIONS_DOCS_URL}."
                ),
            )
            return

        gh_source_uris = self.get_github_source_uris(module_name)
        if not gh_source_uris:
            self.report(
                BcrValidationResult.FAILED,
                (
                    f"{module_name}@{version}: Could not determine source URI. "
                    "Please ensure that metadata.json contains at least one GitHub repository."
                ),
            )
            return

        source_uri = self.get_expected_source_uri(attestations[0].url)
        if not source_uri:
            self.report(
                BcrValidationResult.FAILED,
                (f"{module_name}@{version}: Only GitHub repositories are currently supported."),
            )
            return

        if source_uri not in gh_source_uris:
            self.report(
                BcrValidationResult.FAILED,
                (
                    f"{module_name}@{version}: Expected source URI {source_uri}, "
                    f"but got {', '.join(gh_source_uris)}."
                ),
            )
            return

        success = True
        tmp_dir = tempfile.mkdtemp()
        for attestation in attestations:
            try:
                self._verifier.run(attestation, source_uri, version, tmp_dir)
            except attestations_lib.Error as ex:
                self.report(BcrValidationResult.FAILED, f"{module_name}@{version}: {ex}")
                success = False

        if success:
            self.report(
                BcrValidationResult.GOOD,
                f"Successfully verified attestations for {module_name}@{version}.",
            )

    def get_github_source_uris(self, module_name):
        repos = self.registry.get_metadata(module_name)["repository"]
        matches = [GITHUB_REPO_RE.match(r) for r in repos]
        return [f"github.com/{m.group(1)}" for m in matches if m]

    def get_expected_source_uri(self, attestation_url):
        m = GITHUB_URL_RE.search(attestation_url)
        if not m:
            return None

        return f"github.com/{m.group(1)}"

    def global_checks(self):
        """General global checks for BCR"""
        self.verify_module_name_conflict()
        self.verify_no_symlinks()

    def getValidationReturnCode(self):
        # Calculate the overall return code
        # 0: All good
        # 1: BCR validation failed
        # 42: BCR validation passes, but some changes need BCR maintainer review before triggering follow up BCR presubmit jobs.
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
        "--check_all",
        action="store_true",
        help="Check all Bazel modules in the registry, ignore other --check flags.",
    )
    parser.add_argument(
        "--check_metadata",
        action="append",
        help="Check metadata for given modules in the registry.",
    )
    parser.add_argument(
        "--check_all_metadata",
        action="store_true",
        help="Check all Bazel module metadata in the registry.",
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Should the script try to fix the detected validation errors.",
    )
    parser.add_argument(
        "--skip_validation",
        type=str,
        default=[],
        action="append",
        help="Bypass the given step for validating modules. Supported values are: "
        + '"url_stability", to bypass the URL stability check; '
        + '"presubmit_yml", to bypass the presubmit.yml check; '
        + '"presubmit_task", to bypass the presubmit.yml tasks check; '
        + '"source_repo", to bypass the source repo verification; '
        + '"attestations", to skip the attestations check. '
        + "This flag can be repeated to skip multiple validations.",
    )

    args = parser.parse_args(argv)

    if not args.check_all and not args.check and not args.check_all_metadata and not args.check_metadata:
        parser.print_help()
        return -1

    registry = RegistryClient(args.registry)

    # Parse what module versions we should validate
    module_versions = parse_module_versions(registry, args.check_all, args.check)
    if module_versions:
        print_expanded_group("Module versions to be validated:")
        for name, version in module_versions:
            print(f"{name}@{version}")

    # TODO: Read url from flags to support forks.
    upstream = UpstreamRegistry(modules_dir_url=UPSTREAM_MODULES_DIR_URL)

    # Validate given module version.
    validator = BcrValidator(registry, upstream, args.fix)
    for name, version in module_versions:
        validator.validate_module(name, version, args.skip_validation)

    if args.check_all_metadata:
        # Validate all metadata.json
        validator.validate_metadata(validator.registry.get_all_modules())
    else:
        # Validate metadata.json for given modules and all modified modules.
        modules = [] if not args.check_metadata else args.check_metadata
        modules_to_validate = set(modules + [name for name, _ in module_versions])
        validator.validate_metadata(list(modules_to_validate))

    # Perform some global checks
    validator.global_checks()

    return validator.getValidationReturnCode()


if __name__ == "__main__":
    # Under 'bazel run' we want to run within the source folder instead of the execroot.
    if os.getenv("BUILD_WORKSPACE_DIRECTORY"):
        os.chdir(os.getenv("BUILD_WORKSPACE_DIRECTORY"))
    sys.exit(main())
