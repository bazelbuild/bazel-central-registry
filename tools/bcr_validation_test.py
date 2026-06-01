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
from tools.bcr_validation import BcrValidator, BcrValidationException, BcrValidationResult

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
            "CRITICAL FAILURE: strip_prefix '..' resolves outside the extraction directory." in str(e.exception)
        )

    def test_fail_module_dot_bazel_no_absolute_strip_prefix(self):
        self.bcr_validator.registry.get_source = MagicMock(return_value=dict(strip_prefix="/fake2"))
        with self.assertRaises(BcrValidationException) as e:
            self.bcr_validator.verify_module_dot_bazel(module_name="foobar", version="0.0.0")
        self.assertTrue(
            "CRITICAL FAILURE: strip_prefix '/fake2' resolves outside the extraction directory." in str(e.exception)
        )

    def test_fail_module_dot_bazel_overlay_escapes_extraction_root(self):
        """Overlay destination must be rejected if it escapes the extraction root.

        Regression test for #8583/#8584: Even when strip_prefix is valid
        (stays within output_dir), overlay files with ../ paths relative to
        source_root must not escape the extraction root (output_dir).
        """
        self.bcr_validator.registry.get_source = MagicMock(
            return_value=dict(
                strip_prefix="project-1.0/src",
                overlay={"../../../etc/evil.bzl": "sha256-fake"},
            )
        )
        self.bcr_validator._download_source_archive = MagicMock()

        # Mock paths so their .is_symlink() returns False and they don't trigger symlink warnings
        mock_module_file = MagicMock()
        mock_module_file.is_symlink.return_value = False
        self.bcr_validator.registry.get_module_dot_bazel_path = MagicMock(return_value=mock_module_file)

        mock_overlay_dir = MagicMock()
        mock_overlay_file = MagicMock()
        mock_overlay_file.is_symlink.return_value = False
        mock_overlay_dir.__truediv__.return_value = mock_overlay_file
        self.bcr_validator.registry.get_overlay_dir = MagicMock(return_value=mock_overlay_dir)

        # Run verify_module_dot_bazel.
        # It will proceed past download (mocked) and then validate the overlay.
        # It should report a failure because "../../etc/evil.bzl" relative to "project-1.0/src"
        # escapes the extraction root ("source_root").
        try:
            self.bcr_validator.verify_module_dot_bazel(module_name="foobar", version="0.0.0")
        except Exception:
            pass

        # Verify that BcrValidationResult.FAILED was reported for the overlay escaping check
        reported_failures = [
            msg for res_type, msg in self.bcr_validator.validation_results if res_type == BcrValidationResult.FAILED
        ]
        self.assertTrue(
            any("must point inside the extraction directory" in msg for msg in reported_failures),
            f"Expected overlay containment failure report, got: {reported_failures}",
        )


if __name__ == "__main__":
    unittest.main()
