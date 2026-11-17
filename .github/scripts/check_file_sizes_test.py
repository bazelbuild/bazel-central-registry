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
"""Unit tests for .github/scripts/check_file_sizes.py."""

import contextlib
from contextlib import redirect_stderr
import io
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from unittest import mock

import check_file_sizes


class CheckFileSizesTest(unittest.TestCase):
    """Tests for .github/scripts/check_file_sizes.py."""

    @contextlib.contextmanager
    def _temp_repo_dir(self):
        repo_dir = tempfile.mkdtemp()
        try:
            yield repo_dir
        finally:

            def _handle_readonly(func, path, _exc_info):
                os.chmod(path, stat.S_IWRITE)
                func(path)

            shutil.rmtree(repo_dir, onerror=_handle_readonly)

    def _git(self, repo_dir, *args):
        subprocess.run(
            [
                "git",
                "-C",
                repo_dir,
                "-c",
                "user.name=Test User",
                "-c",
                "user.email=test@example.com",
                "-c",
                "commit.gpgsign=false",
                *args,
            ],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def _write_file(self, repo_dir, rel_path, size_bytes, fill_byte=b"x"):
        full_path = os.path.join(repo_dir, rel_path)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, "wb") as f:
            f.write(fill_byte * size_bytes)

    def test_default_limit_and_repo_dir(self):
        self.assertEqual(check_file_sizes.BYTES_PER_MIB, 1024 * 1024)
        self.assertEqual(check_file_sizes.MAX_FILE_SIZE_BYTES, 25 * 1024 * 1024)
        self.assertTrue(os.path.isfile(os.path.join(check_file_sizes.DEFAULT_REPO_DIR, "bazel_registry.json")))

    def test_allows_blobs_at_or_below_limit_and_rejects_above_limit(self):
        one_mib = 1024 * 1024
        with self._temp_repo_dir() as repo_dir:
            self._git(repo_dir, "init")
            self._git(repo_dir, "checkout", "-B", "main")
            self._write_file(repo_dir, "exact_limit.bin", one_mib, fill_byte=b"\0")
            self._git(repo_dir, "add", "exact_limit.bin")
            self._git(repo_dir, "commit", "-m", "Add file at limit")

            self.assertEqual(
                check_file_sizes.find_oversized_blobs(repo_dir, base_ref="origin/main", max_bytes=one_mib),
                [],
            )

            self._write_file(repo_dir, "dir with spaces/over limit.bin", one_mib + 1, fill_byte=b"\0")
            self._git(repo_dir, "add", "dir with spaces/over limit.bin")
            self._git(repo_dir, "commit", "-m", "Add oversized file")

            oversized = check_file_sizes.find_oversized_blobs(repo_dir, base_ref="origin/main", max_bytes=one_mib)
            self.assertEqual(oversized, [("dir with spaces/over limit.bin", one_mib + 1)])

            exit_code, stderr_text = self._run_cli(repo_dir, max_bytes=one_mib, base_ref="origin/main")
            self.assertEqual(exit_code, 1)
            self.assertIn("exceed the 1 MiB (1,048,576 bytes) limit", stderr_text)
            self.assertIn("dir with spaces/over limit.bin: 1.00 MiB (1,048,577 bytes)", stderr_text)
            self.assertIn("internal clone of this repository", stderr_text)
            self.assertIn("source.json", stderr_text)

    def test_catches_oversized_blob_added_then_deleted_in_commit_range(self):
        with self._temp_repo_dir() as repo_dir:
            self._git(repo_dir, "init")
            self._git(repo_dir, "checkout", "-B", "main")
            self._write_file(repo_dir, "small.txt", 32)
            self._git(repo_dir, "add", "small.txt")
            self._git(repo_dir, "commit", "-m", "Initial commit")
            self._git(repo_dir, "update-ref", "refs/remotes/origin/main", "HEAD")

            self._git(repo_dir, "checkout", "-b", "feature")
            self._write_file(repo_dir, "transient_archive.tar", 2048)
            self._git(repo_dir, "add", "transient_archive.tar")
            self._git(repo_dir, "commit", "-m", "Add large archive")

            self._git(repo_dir, "rm", "transient_archive.tar")
            self._git(repo_dir, "commit", "-m", "Delete large archive")

            oversized = check_file_sizes.find_oversized_blobs(repo_dir, base_ref="origin/main", max_bytes=1000)
            self.assertEqual(oversized, [("transient_archive.tar", 2048)])

    def test_fetches_github_base_ref_when_missing_locally(self):
        with self._temp_repo_dir() as origin_dir, self._temp_repo_dir() as clone_dir:
            self._git(origin_dir, "init", "--bare")
            self._git(clone_dir, "init")
            self._git(clone_dir, "checkout", "-B", "main")
            self._git(clone_dir, "remote", "add", "origin", origin_dir)
            self._write_file(clone_dir, "small.txt", 32)
            self._git(clone_dir, "add", "small.txt")
            self._git(clone_dir, "commit", "-m", "Initial commit")
            self._git(clone_dir, "push", "origin", "main")
            self._git(clone_dir, "update-ref", "-d", "refs/remotes/origin/main")

            self._git(clone_dir, "checkout", "-b", "pr-branch")
            self._write_file(clone_dir, "temp_bundle.bin", 2048)
            self._git(clone_dir, "add", "temp_bundle.bin")
            self._git(clone_dir, "commit", "-m", "Add oversized file")
            self._git(clone_dir, "rm", "temp_bundle.bin")
            self._git(clone_dir, "commit", "-m", "Remove oversized file")

            with mock.patch.dict(os.environ, {"GITHUB_BASE_REF": "main"}):
                exit_code, stderr_text = self._run_cli(clone_dir, max_bytes=1000)
            self.assertEqual(exit_code, 1)
            self.assertIn("temp_bundle.bin", stderr_text)

    def test_resolves_upstream_main_when_github_base_ref_unset(self):
        with self._temp_repo_dir() as repo_dir:
            self._git(repo_dir, "init")
            self._git(repo_dir, "checkout", "-B", "main")
            self._write_file(repo_dir, "small.txt", 32)
            self._git(repo_dir, "add", "small.txt")
            self._git(repo_dir, "commit", "-m", "Initial commit")
            self._git(repo_dir, "update-ref", "refs/remotes/upstream/main", "HEAD")

            self._git(repo_dir, "checkout", "-b", "fork-branch")
            self._write_file(repo_dir, "large_overlay.c", 2048)
            self._git(repo_dir, "add", "large_overlay.c")
            self._git(repo_dir, "commit", "-m", "Add large overlay")
            self._git(repo_dir, "rm", "large_overlay.c")
            self._git(repo_dir, "commit", "-m", "Remove large overlay")

            with mock.patch.dict(os.environ, {}, clear=False):
                os.environ.pop("GITHUB_BASE_REF", None)
                exit_code, stderr_text = self._run_cli(repo_dir, max_bytes=1000)
            self.assertEqual(exit_code, 1)
            self.assertIn("large_overlay.c", stderr_text)

    def _run_cli(self, repo_dir, max_bytes, base_ref=None):
        cli_args = ["--repo-dir", repo_dir, "--max-bytes", str(max_bytes)]
        if base_ref is not None:
            cli_args.extend(["--base-ref", base_ref])
        err = io.StringIO()
        with redirect_stderr(err):
            code = check_file_sizes.main(cli_args)
        return code, err.getvalue()


if __name__ == "__main__":
    unittest.main()
