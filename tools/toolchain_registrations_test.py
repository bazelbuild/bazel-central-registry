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

import contextlib
import io
import json
import pathlib
import subprocess
import tempfile
import unittest

from unittest.mock import patch

from tools.toolchain_registrations import (
    AnalysisError,
    Bazel,
    Call,
    CallResult,
    ModuleResult,
    analyze_module,
    assign_patterns,
    describe_bazel_error,
    find_registration_calls,
    format_report,
    main,
)


def registration(pattern, *targets, error=None):
    if error:
        return {"pattern": pattern, "error": error}
    return {"pattern": pattern, "targets": list(targets)}


def toolchain(label, toolchain_type, owner):
    return {"label": label, "toolchain_type": toolchain_type, "toolchain_type_owner": owner}


class FindRegistrationCallsTest(unittest.TestCase):
    def test_returns_non_dev_calls(self):
        calls = find_registration_calls(
            """module(name = "foo")

register_toolchains("//:a", "@hub//:all")
register_toolchains(
    "//:b",
    dev_dependency = False,
)
register_toolchains("//:c", dev_dependency = True)
"""
        )
        self.assertEqual(calls, [Call(3, 3, ["//:a", "@hub//:all"], []), Call(4, 7, ["//:b"], [])])

    def test_records_what_isnt_a_literal(self):
        calls = find_registration_calls(
            """register_toolchains("//:a", "@" + NAME + "//:all")
[register_toolchains(name) for name in NAMES]
register_toolchains("//:b", dev_dependency = IS_DEV)
register_toolchains(name, dev_dependency = True)
"""
        )
        self.assertEqual(
            calls,
            [
                Call(1, 1, ["//:a"], ["'@' + NAME + '//:all'"]),
                Call(2, 2, [], ["name"]),
                Call(3, 3, ["//:b"], [], dev_dependency_known=False),
            ],
        )


class AssignPatternsTest(unittest.TestCase):
    CALLS = [
        Call(1, 1, ["//:a"], ["'@' + NAME + '//:all'"]),
        Call(2, 2, [], ["name"]),
        Call(3, 3, ["//:b"], [], dev_dependency_known=False),
        Call(4, 4, ["//:c"], [], dev_dependency_known=False),
    ]

    def test_with_registered_patterns(self):
        registered = ["//:a", "@x//:all", "@y//:all", "//:b"]
        self.assertEqual(
            assign_patterns(self.CALLS, registered),
            [
                (self.CALLS[0], ["//:a", "@x//:all", "@y//:all"]),
                (self.CALLS[2], ["//:b"]),
            ],
        )

    def test_unexplained_registered_patterns(self):
        self.assertEqual(
            assign_patterns([Call(5, 5, ["//:a"], [])], ["//:a", "@x//:all"]),
            [(Call(5, 5, ["//:a"], []), ["//:a"]), (Call(1, 1, [], []), ["@x//:all"])],
        )


class DescribeBazelErrorTest(unittest.TestCase):
    def test_prefers_starlark_root_cause_with_location(self):
        stderr = """INFO: Invocation ID: 123
ERROR: Traceback (most recent call last):
\tFile "/ob/external/m+/toolchains.bzl", line 7, column 26, in <toplevel>
\t\tfoo_toolchain = rule(
Error in rule: rule() got unexpected keyword argument 'incompatible_use_toolchain_transition'
ERROR: error loading package '@@m+//toolchains': initialization of module 'toolchains.bzl' failed
"""
        self.assertEqual(
            describe_bazel_error(stderr, 7, []),
            "m+/toolchains.bzl:7:26: Error in rule: rule() got unexpected keyword argument"
            " 'incompatible_use_toolchain_transition'",
        )

    def test_joins_multiline_messages_and_skips_builtins(self):
        stderr = """ERROR: Traceback (most recent call last):
\tFile "/ob/external/m+/BUILD", line 4, column 8, in <toplevel>
\t\tcc_test(
\tFile "/virtual_builtins_bzl/bazel/exports.bzl", line 40, column 9, in _removed_rule_failure
Error in fail:
         This rule has been removed from Bazel.
         Please add a `load()` statement for it.
Loading: 1 packages loaded
ERROR: error loading package '@@m+//': compilation failed
"""
        self.assertEqual(
            describe_bazel_error(stderr, 7, []),
            "m+/BUILD:4:8: Error in fail: This rule has been removed from Bazel. Please add a `load()` statement for it.",
        )

    def test_falls_back_to_error_lines_and_strips_paths(self):
        stderr = """ERROR: C:/b/ob/external/m+/defs.bzl:26:12: The CcInfo symbol has been removed, add the following:
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
    currently loading: @@m+//
ERROR: Error loading '@@m+//:defs.bzl' requested by file:///registry/modules/m/1.0/MODULE.bazel:3:4
"""
        self.assertEqual(
            describe_bazel_error(stderr, 7, ["file:///registry/"]),
            "m+/defs.bzl:26:12: The CcInfo symbol has been removed, add the following:"
            ' load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")\n'
            "Error loading '@@m+//:defs.bzl' requested by modules/m/1.0/MODULE.bazel:3:4",
        )

    def test_falls_back_to_exit_code_and_tail(self):
        self.assertEqual(
            describe_bazel_error("\nsomething\nwent wrong\n", 37, []), "exit code 37\nsomething\nwent wrong"
        )


class ShowToolchainsTest(unittest.TestCase):
    def show_toolchains(self, returncode, stdout, stderr=""):
        bazel = Bazel(pathlib.Path("/ws"), [], 60, ["/registry/"])
        result = subprocess.CompletedProcess([], returncode, stdout, stderr)
        with patch.object(bazel, "_run", return_value=result) as run:
            module_and_registrations = bazel.show_toolchains("foo")
        run.assert_called_once_with("mod", "show_toolchains", "foo", "--output=json")
        return module_and_registrations

    def test_parses_output_and_strips_paths(self):
        registrations = [
            registration("//:all", toolchain("@@foo+//:t", "@@foo+//:type", "foo@1.0")),
            registration("//:missing", error="no such target, defined by /ob/external/foo+/BUILD"),
            registration("//:configurable", {"label": "@@foo+//:configurable", "error": "boom"}),
        ]
        stdout = json.dumps({"module": "foo@1.0", "registrations": registrations}) + "\n"
        self.assertEqual(
            self.show_toolchains(2, stdout),
            (
                "foo@1.0",
                [
                    registration("//:all", toolchain("@@foo+//:t", "@@foo+//:type", "foo@1.0")),
                    registration("//:missing", error="no such target, defined by foo+/BUILD"),
                    registration("//:configurable", {"label": "@@foo+//:configurable", "error": "boom"}),
                ],
            ),
        )

    def test_unsupported_bazel_version(self):
        stderr = "ERROR: Invalid subcommand, choose one from : (deps, graph).\n"
        with self.assertRaisesRegex(AnalysisError, "doesn't support `bazel mod show_toolchains`"):
            self.show_toolchains(2, "", stderr)

    def test_failure_without_output(self):
        stderr = "ERROR: In module argument foo: Module foo does not exist in the dependency graph.\n"
        with self.assertRaisesRegex(AnalysisError, "^In module argument foo: Module foo does not exist"):
            self.show_toolchains(2, "", stderr)

    def test_multiple_versions(self):
        stdout = "".join(json.dumps({"module": m, "registrations": []}) + "\n" for m in ("foo@1.0", "foo@2.0"))
        with self.assertRaisesRegex(AnalysisError, "multiple versions of foo: foo@1.0, foo@2.0"):
            self.show_toolchains(0, stdout)


class AnalyzeModuleTest(unittest.TestCase):
    def analyze(self, module_dot_bazel, bazel_version=None, **kwargs):
        with tempfile.TemporaryDirectory() as root:
            if bazel_version:
                (pathlib.Path(root) / ".bazelversion").write_text(f"{bazel_version}\n")
            module_dir = pathlib.Path(root) / "modules" / "foo" / "1.0"
            module_dir.mkdir(parents=True)
            (module_dir / "MODULE.bazel").write_text(module_dot_bazel)
            return analyze_module(root, "foo", "1.0", **kwargs)

    @patch("tools.toolchain_registrations.Bazel")
    def test_no_bazel_without_non_dev_registrations(self, bazel):
        result = self.analyze('register_toolchains("//:a", dev_dependency = True)\n')
        self.assertEqual(result, ModuleResult("foo", "1.0", "modules/foo/1.0/MODULE.bazel", []))
        self.assertEqual(result.status, "no non-dev registrations")
        bazel.assert_not_called()

    @patch("tools.toolchain_registrations.Bazel")
    def test_unparsable_file(self, bazel):
        result = self.analyze('\nregister_toolchains("//:a"\n')
        self.assertEqual(result.calls[0].call.line, 2)
        self.assertIn("can't parse the file", result.calls[0].problems[0][1])
        bazel.assert_not_called()

    @patch("tools.toolchain_registrations.Bazel")
    def test_findings_and_problems(self, bazel):
        bazel.return_value.show_toolchains.return_value = (
            "foo@1.0",
            [
                registration(
                    "//:all",
                    toolchain("@@foo+//:t", "@@bazel_tools//tools/cpp:toolchain_type", "bazel_tools@_"),
                    toolchain("@@foo+//:u", "@@foo+//:type", "foo@1.0"),
                ),
                registration("@unknown//:all", error="No repository visible as '@unknown' from repository '@@foo+'"),
                registration("@hub//:all", toolchain("@@foo++e+hub//:t", "@@foo+//:type", "foo@1.0")),
            ],
        )
        result = self.analyze('register_toolchains("//:all", "@" + HUB + "//:all", "@unknown//:all")\n')
        call = Call(1, 1, ["//:all", "@unknown//:all"], ["'@' + HUB + '//:all'"])
        self.assertEqual(
            result.calls,
            [
                CallResult(
                    call,
                    ["//:all", "@unknown//:all", "@hub//:all"],
                    {"//:all": ["@@bazel_tools//tools/cpp:toolchain_type"]},
                    [("@unknown//:all", "No repository visible as '@unknown' from repository '@@foo+'")],
                )
            ],
        )
        self.assertEqual(result.status, "registers toolchains for types it doesn't own, couldn't be fully analyzed")
        bazel.return_value.show_toolchains.assert_called_once_with("foo")
        bazel.return_value.shutdown.assert_called_once()

    @patch("tools.toolchain_registrations.Bazel")
    def test_uses_registry_bazel_version(self, bazel):
        bazel.return_value.show_toolchains.return_value = ("foo@1.0", [])
        self.analyze('register_toolchains("//:a")\n', bazel_version="10.1.0")
        self.assertEqual(bazel.call_args.args[4], "10.1.0")

    @patch("tools.toolchain_registrations.Bazel")
    def test_existing_workspace(self, bazel):
        bazel.return_value.show_toolchains.side_effect = AnalysisError("boom")
        result = self.analyze(
            'register_toolchains("//:a")\nregister_toolchains("//:b")\n',
            workspace="/ws",
            startup_options=["--output_user_root=C:/b"],
        )
        self.assertEqual([call.problems for call in result.calls], [[(None, "boom")], [(None, "boom")]])
        self.assertEqual(bazel.call_args.args[:3], (pathlib.Path("/ws"), ["--output_user_root=C:/b"], 900))
        self.assertIsNone(bazel.call_args.args[4])
        bazel.return_value.shutdown.assert_not_called()


class ReportTest(unittest.TestCase):
    RESULT = ModuleResult(
        "foo",
        "1.0",
        "modules/foo/1.0/MODULE.bazel",
        [
            CallResult(
                Call(3, 5, ["//:all"], []),
                ["//:all"],
                {"//:all": ["@@bazel_tools//tools/cpp:toolchain_type"]},
                [],
            ),
            CallResult(
                Call(7, 7, ["@a//:all", "@b//:all"], []),
                ["@a//:all", "@b//:all"],
                {},
                [("@a//:all", "boom"), ("@b//:all", "boom")],
            ),
        ],
    )

    def test_format_report(self):
        report = format_report(self.RESULT)
        self.assertIn("foo@1.0: registers toolchains for types it doesn't own, couldn't be fully analyzed", report)
        self.assertIn(
            "modules/foo/1.0/MODULE.bazel:3-5: These registrations apply to all dependents of foo, but the module"
            " doesn't own their toolchain types:\n- //:all: @@bazel_tools//tools/cpp:toolchain_type\n",
            report,
        )
        self.assertIn("comment `@bazel-io skip_check toolchain_registrations` on the PR", report)
        self.assertIn(
            "modules/foo/1.0/MODULE.bazel:7: Couldn't determine which toolchain types this registers:\n"
            "- @a//:all, @b//:all: boom",
            report,
        )

    @patch("tools.toolchain_registrations.analyze_module")
    def test_main_fails_on_findings(self, analyze_module):
        analyze_module.return_value = self.RESULT
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main(["--check=foo@1.0", "--workspace=/ws", "--bazel_startup_option=--foo"]), 1)
        analyze_module.assert_called_once_with(".", "foo", "1.0", "/ws", ["--foo"])

    @patch("tools.toolchain_registrations.analyze_module")
    def test_main_passes_without_findings(self, analyze_module):
        analyze_module.return_value = self.RESULT._replace(calls=self.RESULT.calls[1:])
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main(["--check=foo@1.0"]), 0)

    def test_workspace_requires_one_check(self):
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            main(["--check=foo@1.0", "--check=bar@1.0", "--workspace=/ws"])


if __name__ == "__main__":
    unittest.main()
