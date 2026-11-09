#!/usr/bin/env python3
#
# Copyright 2026 The Bazel Authors. All rights reserved.
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

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from registry import RegistryClient
from tools.bcr_validation import (
    BcrValidationException,
    BcrValidationResult,
    BcrValidator,
    is_ref_in_original_repo,
)

from unittest.mock import MagicMock, patch


class TestBcrValidation(unittest.TestCase):
    def setUp(self):
        registry = RegistryClient("/fake")

        self.bcr_validator = BcrValidator(registry=registry, upstream=None, should_fix=False)

    def test_fail_module_dot_bazel_source_is_not_archive(self):
        self.bcr_validator.registry.get_source = MagicMock(return_value=dict(type="not_archive"))
        with self.assertRaises(BcrValidationException) as e:
            self.bcr_validator.verify_module_dot_bazel(module_name="foobar", version="0.0.0")
        self.assertEqual('Module source "type" must be "archive" (the default)', str(e.exception))

    def test_fail_module_dot_bazel_no_relative_strip_prefix_outside_module(self):
        self.bcr_validator.registry.get_source = MagicMock(return_value=dict(strip_prefix=".."))
        with self.assertRaises(BcrValidationException) as e:
            self.bcr_validator.verify_module_dot_bazel(module_name="foobar", version="0.0.0")
        self.assertTrue(
            "CRITICAL FAILURE: strip_prefix '..' resolves outside the extraction directory. Resolved to: /"
            in str(e.exception)
        )

    def test_fail_module_dot_bazel_no_absolute_strip_prefix(self):
        self.bcr_validator.registry.get_source = MagicMock(return_value=dict(strip_prefix="/fake2"))
        with self.assertRaises(BcrValidationException) as e:
            self.bcr_validator.verify_module_dot_bazel(module_name="foobar", version="0.0.0")
        self.assertTrue(
            "CRITICAL FAILURE: strip_prefix '/fake2' resolves outside the extraction directory. Resolved to: /"
            in str(e.exception)
        )

    def test_fail_module_dot_bazel_strip_prefix_not_in_archive(self):
        self.bcr_validator.registry.get_source = MagicMock(return_value=dict(strip_prefix="missing"))
        self.bcr_validator._download_source_archive = MagicMock(
            side_effect=lambda _source, output_dir: (output_dir / "actual").mkdir(parents=True)
        )
        self.bcr_validator.verify_module_dot_bazel(module_name="foobar", version="0.0.0")
        self.assertEqual(1, self.bcr_validator.getValidationReturnCode())
        _, message = self.bcr_validator.validation_results[-1]
        self.assertIn("strip_prefix 'missing' may not match the archive layout", message)

    def test_is_ref_in_original_repo_rejects_pull_request_refs(self):
        # Pull-request refs (refs/pull/N/head and refs/pull/N/merge) are created by
        # GitHub for any opened PR, including from forks, and point at commits that
        # were never merged into the repository. They must never be accepted as
        # authentic upstream references. The guard rejects them before any network
        # call, so this check runs offline.
        for ref in (
            "refs/pull/1234/head",
            "pull/1234/head",
            "refs/pull/1234/merge",
            "pull/1234/merge",
        ):
            self.assertFalse(is_ref_in_original_repo("fake/repo", ref), ref)

    def _verify_source_repo(self, repositories, source_url):
        self.bcr_validator.validation_results.clear()
        self.bcr_validator.registry.get_source = MagicMock(return_value={"url": source_url})
        self.bcr_validator.registry.get_metadata = MagicMock(return_value={"repository": repositories})
        self.bcr_validator.verify_source_archive_url_match_github_repo(module_name="foobar", version="1.0.0")
        return self.bcr_validator.validation_results[-1][0]

    def test_verify_source_archive_url_match_https_github_repo(self):
        repo = "https://github.com/example-owner/example-repo"
        release_url = f"{repo}/releases/download/v1.0.0/pkg.tar.gz"
        archive_url = f"{repo}/archive/0123456789abcdef0123456789abcdef01234567.tar.gz"

        with patch("tools.bcr_validation.requests.get") as mock_get:
            self.assertEqual(BcrValidationResult.GOOD, self._verify_source_repo([repo], release_url))
            self.assertEqual(BcrValidationResult.GOOD, self._verify_source_repo([f"{repo}/"], release_url))
            self.assertEqual(
                BcrValidationResult.GOOD,
                self._verify_source_repo(
                    ["https://mirror.bazel.build/github.com/example-owner/example-repo/"],
                    "https://mirror.bazel.build/github.com/example-owner/example-repo/pkg.tar.gz",
                ),
            )
            self.assertEqual(
                BcrValidationResult.FAILED,
                self._verify_source_repo([repo], f"{repo}/archive/refs/pull/1234/head.tar.gz"),
            )
            self.assertEqual(BcrValidationResult.FAILED, self._verify_source_repo(["https://github.com/"], release_url))
            mock_get.assert_not_called()

            mock_get.return_value = MagicMock(status_code=200, json=MagicMock(return_value={"isSpoofed": False}))
            self.assertEqual(BcrValidationResult.GOOD, self._verify_source_repo([f"{repo}/"], archive_url))

            mock_get.return_value = MagicMock(status_code=200, json=MagicMock(return_value={"isSpoofed": True}))
            self.assertEqual(
                BcrValidationResult.FAILED,
                self._verify_source_repo(["https://example.org/foo", repo], archive_url),
            )

    def _run_git(self, repo_dir: Path, *args: str):
        env = {
            **os.environ,
            "GIT_CONFIG_NOSYSTEM": "1",
            "HOME": str(repo_dir),
            "XDG_CONFIG_HOME": str(repo_dir),
        }
        return subprocess.run(
            ["git", *args],
            cwd=repo_dir,
            env=env,
            check=True,
            capture_output=True,
        )

    def _init_git_repo_on_main(self, repo_dir: Path):
        self._run_git(repo_dir, "init", "-b", "main")
        self._run_git(repo_dir, "config", "user.email", "test@example.com")
        self._run_git(repo_dir, "config", "user.name", "Test User")
        self._run_git(repo_dir, "config", "commit.gpgsign", "false")
        (repo_dir / "modules").mkdir(exist_ok=True)
        (repo_dir / "README.md").write_text("BCR\n", encoding="utf-8")
        self._run_git(repo_dir, "add", "README.md")
        self._run_git(repo_dir, "commit", "-m", "initial")

    def test_verify_no_binary_files_fails_for_added_modified_and_renamed_binary_files(self):
        # Adding, modifying into binary, or renaming a binary file relative to
        # main should report BcrValidationResult.FAILED (exit code 1) without
        # crashing on renames.
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp_dir:
            repo_dir = Path(tmp_dir)
            self._init_git_repo_on_main(repo_dir)

            existing_dir = repo_dir / "modules" / "bar" / "1.0.0"
            existing_dir.mkdir(parents=True)
            (existing_dir / "notes.txt").write_text("plain text\n", encoding="utf-8")
            (existing_dir / "old.bin").write_bytes(b"\x00\x01\x02\x03")
            self._run_git(repo_dir, "add", "-f", "modules")
            self._run_git(repo_dir, "commit", "-m", "seed bar")

            self._run_git(repo_dir, "checkout", "-b", "feature")

            mod_dir = repo_dir / "modules" / "foo" / "1.0.0"
            mod_dir.mkdir(parents=True)
            (mod_dir / "MODULE.bazel").write_text('module(name = "foo", version = "1.0.0")\n', encoding="utf-8")
            (mod_dir / ".MODULE.bazel.swp").write_bytes(b"b0VIM 9.1\x00\x00\x00\x01\x02")
            (existing_dir / "notes.txt").write_bytes(b"now binary\x00data")
            self._run_git(repo_dir, "mv", "modules/bar/1.0.0/old.bin", "modules/bar/1.0.0/renamed.bin")

            self._run_git(repo_dir, "add", "-f", "modules")
            self._run_git(repo_dir, "commit", "-m", "changes on feature")

            validator = BcrValidator(registry=RegistryClient(repo_dir), upstream=None, should_fix=False)
            validator.verify_no_binary_files()

            self.assertEqual(1, validator.getValidationReturnCode())
            self.assertEqual(
                [
                    (
                        BcrValidationResult.FAILED,
                        "Binary file is not allowed: 'modules/bar/1.0.0/notes.txt'",
                    ),
                    (
                        BcrValidationResult.FAILED,
                        "Binary file is not allowed: 'modules/bar/1.0.0/renamed.bin'",
                    ),
                    (
                        BcrValidationResult.FAILED,
                        "Binary file is not allowed: 'modules/foo/1.0.0/.MODULE.bazel.swp'",
                    ),
                ],
                validator.validation_results,
            )

    def test_verify_no_binary_files_handles_non_ascii_and_special_filenames(self):
        # Non-ASCII filenames (e.g. emoji) with text contents are allowed, while
        # binary files with emoji, tabs, spaces, or (on Linux) raw non-UTF-8
        # bytes in their paths are parsed cleanly via `-z` + `split("\t", 2)` +
        # PEP 383 `surrogateescape` and escaped safely via `ascii(path)`.
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp_dir:
            repo_dir = Path(tmp_dir)
            self._init_git_repo_on_main(repo_dir)
            self._run_git(repo_dir, "checkout", "-b", "feature")

            mod_dir = repo_dir / "modules" / "foo" / "1.0.0"
            mod_dir.mkdir(parents=True)
            (mod_dir / "📦.txt").write_text("text file with emoji filename\n", encoding="utf-8")
            (mod_dir / "📦.bin").write_bytes(b"\x00\x01")

            if sys.platform == "linux":
                special_name = os.fsdecode(b"tab\tnon_utf8_\xff.bin")
                expected_special = "'modules/foo/1.0.0/tab\\tnon_utf8_\\udcff.bin'"
            elif sys.platform == "win32":
                special_name = "space name.bin"
                expected_special = "'modules/foo/1.0.0/space name.bin'"
            else:
                special_name = "tab\tname.bin"
                expected_special = "'modules/foo/1.0.0/tab\\tname.bin'"
            (mod_dir / special_name).write_bytes(b"\x00\x01")

            self._run_git(repo_dir, "add", "-f", "modules")
            self._run_git(repo_dir, "commit", "-m", "add special filenames")

            validator = BcrValidator(registry=RegistryClient(repo_dir), upstream=None, should_fix=False)
            validator.verify_no_binary_files()

            self.assertEqual(1, validator.getValidationReturnCode())
            self.assertEqual(
                [
                    (
                        BcrValidationResult.FAILED,
                        f"Binary file is not allowed: {expected_special}",
                    ),
                    (
                        BcrValidationResult.FAILED,
                        "Binary file is not allowed: 'modules/foo/1.0.0/\\U0001f4e6.bin'",
                    ),
                ],
                validator.validation_results,
            )

    def test_verify_no_binary_files_uses_merge_base_and_prefers_origin_main(self):
        # 1. Binary files committed to main *after* feature branches off must not
        #    trigger false positives (verifies three-dot merge-base semantics).
        # 2. When refs/remotes/origin/main is ahead of a stale local main,
        #    origin/main is used as the diff base.
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp_dir:
            repo_dir = Path(tmp_dir)
            self._init_git_repo_on_main(repo_dir)
            stale_main_sha = self._run_git(repo_dir, "rev-parse", "HEAD").stdout.decode("utf-8").strip()

            # Advance main with an approved binary file and record it as origin/main,
            # then reset local main back to stale_main_sha to simulate a stale local main.
            other_dir = repo_dir / "modules" / "other" / "1.0.0"
            other_dir.mkdir(parents=True)
            (other_dir / "data.bin").write_bytes(b"\x00\x01\x02")
            self._run_git(repo_dir, "add", "-f", "modules")
            self._run_git(repo_dir, "commit", "-m", "upstream binary commit")
            origin_main_sha = self._run_git(repo_dir, "rev-parse", "HEAD").stdout.decode("utf-8").strip()
            self._run_git(repo_dir, "update-ref", "refs/remotes/origin/main", origin_main_sha)

            # Branch feature from origin/main and reset local main back to stale_main_sha.
            self._run_git(repo_dir, "checkout", "-b", "feature", origin_main_sha)
            self._run_git(repo_dir, "branch", "-f", "main", stale_main_sha)
            mod_dir = repo_dir / "modules" / "foo" / "1.0.0"
            mod_dir.mkdir(parents=True)
            (mod_dir / "MODULE.bazel").write_text('module(name = "foo", version = "1.0.0")\n', encoding="utf-8")
            self._run_git(repo_dir, "add", "modules")
            self._run_git(repo_dir, "commit", "-m", "add text module")

            # Also advance origin/main further with another binary commit after branching.
            self._run_git(repo_dir, "checkout", "--detach", origin_main_sha)
            later_dir = repo_dir / "modules" / "later" / "1.0.0"
            later_dir.mkdir(parents=True)
            (later_dir / "later.bin").write_bytes(b"\x00\x03\x04")
            self._run_git(repo_dir, "add", "-f", "modules")
            self._run_git(repo_dir, "commit", "-m", "post-branch binary on origin/main")
            later_sha = self._run_git(repo_dir, "rev-parse", "HEAD").stdout.decode("utf-8").strip()
            self._run_git(repo_dir, "update-ref", "refs/remotes/origin/main", later_sha)
            self._run_git(repo_dir, "checkout", "feature")

            validator = BcrValidator(registry=RegistryClient(repo_dir), upstream=None, should_fix=False)
            validator.verify_no_binary_files()

            self.assertEqual(0, validator.getValidationReturnCode())
            self.assertEqual(
                [(BcrValidationResult.GOOD, "No binary files detected.")],
                validator.validation_results,
            )

    def test_verify_no_binary_files_ignores_deleted_binary_files(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp_dir:
            repo_dir = Path(tmp_dir)
            self._init_git_repo_on_main(repo_dir)
            mod_dir = repo_dir / "modules" / "foo" / "1.0.0"
            mod_dir.mkdir(parents=True)
            bin_path = mod_dir / ".MODULE.bazel.swp"
            bin_path.write_bytes(b"b0VIM 9.1\x00\x00\x00\x01\x02")
            self._run_git(repo_dir, "add", "-f", "modules")
            self._run_git(repo_dir, "commit", "-m", "add binary on main")

            self._run_git(repo_dir, "checkout", "-b", "feature")
            self._run_git(repo_dir, "rm", str(bin_path))
            self._run_git(repo_dir, "commit", "-m", "remove binary")

            validator = BcrValidator(registry=RegistryClient(repo_dir), upstream=None, should_fix=False)
            validator.verify_no_binary_files()

            self.assertEqual(0, validator.getValidationReturnCode())
            self.assertEqual(
                [(BcrValidationResult.GOOD, "No binary files detected.")],
                validator.validation_results,
            )

    def test_global_checks_fails_on_binary_files_and_handles_missing_refs(self):
        # 1. global_checks() runs verify_no_binary_files() and fails with exit code 1.
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp_dir:
            repo_dir = Path(tmp_dir)
            self._init_git_repo_on_main(repo_dir)
            self._run_git(repo_dir, "checkout", "-b", "feature")
            mod_dir = repo_dir / "modules" / "foo" / "1.0.0"
            mod_dir.mkdir(parents=True)
            (mod_dir / "data.bin").write_bytes(b"\x00\x01")
            self._run_git(repo_dir, "add", "-f", "modules")
            self._run_git(repo_dir, "commit", "-m", "add binary")

            validator = BcrValidator(registry=RegistryClient(repo_dir), upstream=None, should_fix=False)
            validator.global_checks()
            self.assertEqual(1, validator.getValidationReturnCode())

        # 2. Git repo without main/origin/main/upstream/main raises BcrValidationException.
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as no_main_dir:
            no_main_path = Path(no_main_dir)
            self._run_git(no_main_path, "init", "-b", "custom")
            self._run_git(no_main_path, "config", "user.email", "test@example.com")
            self._run_git(no_main_path, "config", "user.name", "Test User")
            self._run_git(no_main_path, "config", "commit.gpgsign", "false")
            (no_main_path / "README.md").write_text("BCR\n", encoding="utf-8")
            self._run_git(no_main_path, "add", "README.md")
            self._run_git(no_main_path, "commit", "-m", "init")
            no_main_validator = BcrValidator(registry=RegistryClient(no_main_path), upstream=None, should_fix=False)
            with self.assertRaises(BcrValidationException):
                no_main_validator.verify_no_binary_files()

        # 3. `git diff` failures (e.g. unrelated/shallow history with no merge base)
        #    are wrapped in BcrValidationException with git's stderr surfaced.
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as orphan_dir:
            orphan_path = Path(orphan_dir)
            self._init_git_repo_on_main(orphan_path)
            self._run_git(orphan_path, "checkout", "--orphan", "unrelated")
            (orphan_path / "README.md").write_text("unrelated\n", encoding="utf-8")
            self._run_git(orphan_path, "add", "README.md")
            self._run_git(orphan_path, "commit", "-m", "unrelated root")
            orphan_validator = BcrValidator(registry=RegistryClient(orphan_path), upstream=None, should_fix=False)
            with self.assertRaises(BcrValidationException) as ctx:
                orphan_validator.verify_no_binary_files()
            self.assertIn("no merge base", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
