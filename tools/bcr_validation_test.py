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

import io
import os
import tarfile
import tempfile
import unittest

import zstandard

from registry import RegistryClient
from tools import bcr_validation
from tools.bcr_validation import BcrValidator, BcrValidationException, is_ref_in_original_repo

from unittest import mock
from unittest.mock import MagicMock


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

    def _make_malicious_tar(self, mode):
        # A tar archive whose only member uses a '..' path-traversal name.
        buf = io.BytesIO()
        with tarfile.open(fileobj=buf, mode=mode) as tar:
            info = tarfile.TarInfo("../escaped.txt")
            data = b"owned"
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))
        return buf.getvalue()

    def _assert_extraction_is_contained(self, filename, archive_bytes):
        extraction_parent = tempfile.mkdtemp()
        output_dir = os.path.join(extraction_parent, "source_root")
        os.makedirs(output_dir)

        def fake_download_file(url, dest):
            with open(dest, "wb") as f:
                f.write(archive_bytes)

        with mock.patch.object(bcr_validation, "download_file", fake_download_file):
            # The PEP 706 'data' filter must reject the traversing member.
            with self.assertRaises(Exception):
                self.bcr_validator._download_source_archive({"url": "https://example.com/%s" % filename}, output_dir)
        # Nothing may be written outside the extraction directory.
        self.assertFalse(os.path.exists(os.path.join(extraction_parent, "escaped.txt")))

    def test_source_archive_extraction_rejects_traversal_tar_gz(self):
        self._assert_extraction_is_contained("evil.tar.gz", self._make_malicious_tar("w:gz"))

    def test_source_archive_extraction_rejects_traversal_tar_zst(self):
        raw = self._make_malicious_tar("w")
        self._assert_extraction_is_contained("evil.tar.zst", zstandard.ZstdCompressor().compress(raw))


if __name__ == "__main__":
    unittest.main()
