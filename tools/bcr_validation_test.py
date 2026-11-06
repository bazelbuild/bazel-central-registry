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
    BcrValidationResult,
    BcrValidator,
    BcrValidationException,
    is_ref_in_original_repo,
    main,
)
from toolchain_registrations import ForeignRegistration, UnanalyzedRegistration

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

    @patch("tools.bcr_validation.analyze_registrations")
    def test_toolchain_registrations_only_warn(self, analyze_registrations):
        analyze_registrations.return_value = (
            [ForeignRegistration(3, "//:toolchain", ["@@bazel_tools//tools/cpp:toolchain_type"])],
            [UnanalyzedRegistration(4, "it doesn't use string literals")],
        )
        self.bcr_validator.verify_toolchain_registrations(module_name="foobar", version="0.0.0")
        self.assertEqual(0, self.bcr_validator.getValidationReturnCode())
        foreign, unanalyzed = self.bcr_validator.validation_results
        self.assertEqual(BcrValidationResult.WARNING, foreign[0])
        self.assertIn("MODULE.bazel:3: //:toolchain registers toolchains for all dependents", foreign[1])
        self.assertIn("@@bazel_tools//tools/cpp:toolchain_type", foreign[1])
        self.assertEqual(BcrValidationResult.WARNING, unanalyzed[0])
        self.assertIn("MODULE.bazel:4: Can't determine", unanalyzed[1])

    @patch("tools.bcr_validation.analyze_registrations")
    def test_toolchain_registrations_good(self, analyze_registrations):
        analyze_registrations.return_value = ([], [])
        self.bcr_validator.verify_toolchain_registrations(module_name="foobar", version="0.0.0")
        self.assertEqual([BcrValidationResult.GOOD], [result for result, _ in self.bcr_validator.validation_results])

    @patch("tools.bcr_validation.analyze_registrations", return_value=([], []))
    def test_toolchain_registrations_run_module_code_only_without_review(self, analyze_registrations):
        for result, run_module_code in [
            (BcrValidationResult.GOOD, True),
            (BcrValidationResult.WARNING, True),
            (BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW, False),
            (BcrValidationResult.FAILED, False),
        ]:
            self.bcr_validator.validation_results = [(result, "message")]
            self.bcr_validator.verify_toolchain_registrations(module_name="foobar", version="0.0.0")
            self.assertEqual(run_module_code, analyze_registrations.call_args.kwargs["run_module_code"], result)

    @patch("tools.bcr_validation.parse_module_versions", return_value=[("foobar", "0.0.0")])
    @patch("tools.bcr_validation.analyze_registrations", return_value=([], []))
    def test_main_checks_toolchain_registrations_after_other_validations(self, analyze_registrations, _):
        def require_review(validator):
            validator.report(BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW, "message")

        with (
            patch.object(BcrValidator, "validate_module"),
            patch.object(BcrValidator, "validate_metadata"),
            patch.object(BcrValidator, "global_checks", autospec=True, side_effect=require_review),
        ):
            self.assertEqual(42, main(["--registry=/fake", "--check=foobar@0.0.0"]))
        self.assertFalse(analyze_registrations.call_args.kwargs["run_module_code"])

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


if __name__ == "__main__":
    unittest.main()
