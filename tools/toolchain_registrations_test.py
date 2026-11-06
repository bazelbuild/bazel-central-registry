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

import pathlib
import tempfile
import unittest

from unittest.mock import patch

from tools.toolchain_registrations import (
    AnalysisError,
    RegistrationAnalyzer,
    analyze_registrations,
    canonicalize_pattern,
    find_registrations,
    owning_module,
)


def rule(name, rule_class, **attrs):
    return {
        "name": name,
        "ruleClass": rule_class,
        "attribute": [{"name": k, "type": "LABEL", "stringValue": v} for k, v in attrs.items()],
    }


def analyzer_for(query_results):
    return RegistrationAnalyzer(query_results.__getitem__)


class FindRegistrationsTest(unittest.TestCase):
    def test_returns_non_dev_registrations(self):
        registrations, unsupported_lines = find_registrations(
            """module(name = "foo")

register_toolchains("//:a", "@hub//:all")
register_toolchains("//:b", dev_dependency = False)
register_toolchains("//:c", dev_dependency = True)
"""
        )
        self.assertEqual(registrations, [(3, "//:a"), (3, "@hub//:all"), (4, "//:b")])
        self.assertEqual(unsupported_lines, [])

    def test_reports_non_literal_arguments(self):
        registrations, unsupported_lines = find_registrations(
            """register_toolchains("//:a", "@" + NAME + "//:all")
[register_toolchains(name) for name in NAMES]
register_toolchains("//:b", dev_dependency = IS_DEV)
register_toolchains(name, dev_dependency = True)
"""
        )
        self.assertEqual(registrations, [(1, "//:a")])
        self.assertEqual(unsupported_lines, [1, 2, 3])


class CanonicalizePatternTest(unittest.TestCase):
    def test_own_repo(self):
        self.assertEqual(canonicalize_pattern("//foo:all", "m+", {}), "@@m+//foo:all")

    def test_apparent_repo(self):
        self.assertEqual(canonicalize_pattern("@hub//foo/...", "m+", {"hub": "m++ext+hub"}), "@@m++ext+hub//foo/...")

    def test_canonical_repo(self):
        self.assertEqual(canonicalize_pattern("@@other+//:all", "m+", {}), "@@other+//:all")

    def test_unknown_repo(self):
        with self.assertRaises(AnalysisError):
            canonicalize_pattern("@unknown//:all", "m+", {})


class OwningModuleTest(unittest.TestCase):
    def test_owning_module(self):
        for label, module in [
            ("@@rules_foo+//:type", "rules_foo"),
            ("@@rules_foo+1.2.3//:type", "rules_foo"),
            ("@@rules_foo++ext+hub//:type", "rules_foo"),
            ("@@rules_foo+1.2.3+ext+hub//:type", "rules_foo"),
            ("@@bazel_tools//tools/cpp:toolchain_type", "bazel_tools"),
        ]:
            self.assertEqual(owning_module(label), module, label)


class RegistrationAnalyzerTest(unittest.TestCase):
    def test_wildcard_ignores_aliases(self):
        toolchain = rule("@@m+//:t", "toolchain", toolchain_type="@@m+//:type")
        analyzer = analyzer_for(
            {
                'kind("^(toolchain) rule$", "@@m+//:all")': [toolchain],
                '"@@m+//:t"': [toolchain],
                '"@@m+//:type"': [rule("@@m+//:type", "toolchain_type")],
            }
        )
        self.assertEqual(analyzer.toolchain_types("@@m+//:all"), {"@@m+//:type"})

    def test_follows_alias_named_explicitly(self):
        alias = rule("@@m++ext+hub//:alias", "alias", actual="@@m+//:t")
        analyzer = analyzer_for(
            {
                'kind("^(toolchain|alias) rule$", "@@m++ext+hub//:alias")': [alias],
                '"@@m++ext+hub//:alias"': [alias],
                '"@@m+//:t"': [rule("@@m+//:t", "toolchain", toolchain_type="@@m+//:type")],
                '"@@m+//:type"': [rule("@@m+//:type", "toolchain_type")],
            }
        )
        self.assertEqual(analyzer.toolchain_types("@@m++ext+hub//:alias"), {"@@m+//:type"})

    def test_follows_toolchain_type_alias(self):
        toolchain = rule("@@m+//:t", "toolchain", toolchain_type="@@bazel_tools//:type")
        analyzer = analyzer_for(
            {
                'kind("^(toolchain|alias) rule$", "@@m+//:t")': [toolchain],
                '"@@m+//:t"': [toolchain],
                '"@@bazel_tools//:type"': [rule("@@bazel_tools//:type", "alias", actual="@@rules_foo+//:type")],
                '"@@rules_foo+//:type"': [rule("@@rules_foo+//:type", "toolchain_type")],
            }
        )
        self.assertEqual(analyzer.toolchain_types("@@m+//:t"), {"@@rules_foo+//:type"})

    def test_alias_with_select(self):
        toolchain = rule("@@m+//:t", "toolchain", toolchain_type="@@m+//:alias")
        analyzer = analyzer_for(
            {
                'kind("^(toolchain|alias) rule$", "@@m+//:t")': [toolchain],
                '"@@m+//:t"': [toolchain],
                '"@@m+//:alias"': [
                    {
                        "name": "@@m+//:alias",
                        "ruleClass": "alias",
                        "attribute": [{"name": "actual", "type": "LABEL", "selectorList": {}}],
                    }
                ],
            }
        )
        with self.assertRaises(AnalysisError):
            analyzer.toolchain_types("@@m+//:t")

    def test_alias_cycle(self):
        toolchain = rule("@@m+//:t", "toolchain", toolchain_type="@@m+//:alias")
        analyzer = analyzer_for(
            {
                'kind("^(toolchain|alias) rule$", "@@m+//:t")': [toolchain],
                '"@@m+//:t"': [toolchain],
                '"@@m+//:alias"': [rule("@@m+//:alias", "alias", actual="@@m+//:alias")],
            }
        )
        with self.assertRaises(AnalysisError):
            analyzer.toolchain_types("@@m+//:t")


class AnalyzeRegistrationsTest(unittest.TestCase):
    def analyze(self, module_dot_bazel, run_module_code):
        with tempfile.TemporaryDirectory() as root:
            module_dir = pathlib.Path(root) / "modules" / "foo" / "1.0"
            module_dir.mkdir(parents=True)
            (module_dir / "MODULE.bazel").write_text(module_dot_bazel)
            return analyze_registrations(root, "foo", "1.0", run_module_code)

    @patch("tools.toolchain_registrations.Bazel")
    def test_no_bazel_without_non_dev_registrations(self, bazel):
        result = self.analyze('register_toolchains("//:a", dev_dependency = True)\n', run_module_code=True)
        self.assertEqual(result, ([], []))
        bazel.assert_not_called()

    @patch("tools.toolchain_registrations.Bazel")
    def test_no_bazel_if_module_code_must_not_run(self, bazel):
        foreign, unanalyzed = self.analyze('register_toolchains("//:a")\n', run_module_code=False)
        self.assertEqual(foreign, [])
        self.assertEqual([registration.line for registration in unanalyzed], [1])
        self.assertIn("BCR maintainer review", unanalyzed[0].reason)
        bazel.assert_not_called()


if __name__ == "__main__":
    unittest.main()
