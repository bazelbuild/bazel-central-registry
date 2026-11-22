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

import unittest
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


if __name__ == "__main__":
    unittest.main()
