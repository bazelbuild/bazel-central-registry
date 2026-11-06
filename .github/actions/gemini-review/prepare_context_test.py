#!/usr/bin/env python3
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
"""Unit tests for prepare_context.py."""

import base64
import json
import os
import pathlib
import tempfile
import unittest
from unittest.mock import patch

import prepare_context


def _b64_content(text):
    return {
        "type": "file",
        "encoding": "base64",
        "content": base64.b64encode(text.encode("utf-8")).decode("ascii"),
    }


class PrepareContextTest(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmp_dir.name)
        self.modules_root = self.root / "modules"
        self.modules_root.mkdir()
        self.old_cwd = os.getcwd()
        os.chdir(self.root)

    def tearDown(self):
        os.chdir(self.old_cwd)
        self.tmp_dir.cleanup()

    def _create_module_on_main(
        self,
        name="foo",
        versions=("1.0.0",),
        maintainers=None,
        presubmit_text=None,
    ):
        if maintainers is None:
            maintainers = [{"github": "alice", "github_user_id": 12345}]
        if presubmit_text is None:
            presubmit_text = (
                "matrix:\n"
                "  platform: [ubuntu2004]\n"
                "  bazel: [7.x]\n"
                "tasks:\n"
                "  verify_targets:\n"
                "    build_targets:\n"
                f"      - '@{name}//:{name}'\n"
            )
        mod_dir = self.modules_root / name
        mod_dir.mkdir(parents=True, exist_ok=True)
        meta = {
            "homepage": f"https://github.com/example/{name}",
            "maintainers": maintainers,
            "repository": [f"github:example/{name}"],
            "versions": list(versions),
            "yanked_versions": {},
        }
        (mod_dir / "metadata.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
        for v in versions:
            ver_dir = mod_dir / v
            ver_dir.mkdir(parents=True, exist_ok=True)
            (ver_dir / "MODULE.bazel").write_text(f'module(name = "{name}", version = "{v}")\n', encoding="utf-8")
            (ver_dir / "source.json").write_text("{}\n", encoding="utf-8")
            (ver_dir / "presubmit.yml").write_text(presubmit_text, encoding="utf-8")
        return meta, presubmit_text

    def test_identifier_and_symlink_validation(self):
        self._create_module_on_main("valid_mod", ("1.0.0",))
        self.assertIsNotNone(prepare_context.resolve_module_dir(self.modules_root, "valid_mod"))
        self.assertIsNone(prepare_context.resolve_module_dir(self.modules_root, "../etc"))
        self.assertIsNone(prepare_context.resolve_module_dir(self.modules_root, "InvalidUpper"))
        self.assertIsNone(prepare_context.resolve_module_dir(self.modules_root, "bad space"))
        self.assertIsNone(prepare_context.resolve_module_dir(self.modules_root, "bad'quote"))

        self.assertIsNotNone(prepare_context.resolve_module_version_dir(self.modules_root, "valid_mod", "1.0.0.bcr.1"))
        self.assertIsNone(prepare_context.resolve_module_version_dir(self.modules_root, "valid_mod", "../1.0.0"))
        self.assertIsNone(prepare_context.resolve_module_version_dir(self.modules_root, "valid_mod", "1.0.0?ref=main"))

        # Reject symlinked module directory or nested file
        outside = self.root / "outside"
        outside.mkdir()
        (self.modules_root / "symlink_mod").symlink_to(outside)
        self.assertIsNone(prepare_context.resolve_module_dir(self.modules_root, "symlink_mod"))

        ver_dir = self.modules_root / "valid_mod" / "1.0.0"
        (ver_dir / "evil_link").symlink_to(outside)
        self.assertIsNone(prepare_context.resolve_path_within(ver_dir, "evil_link"))
        self.assertIsNone(prepare_context.resolve_path_within(ver_dir, "../metadata.json"))

    def test_decode_github_file_content_rejects_non_regular_files(self):
        with self.assertRaises(ValueError):
            prepare_context.decode_github_file_content({"type": "symlink", "encoding": "base64", "content": ""})
        with self.assertRaises(ValueError):
            prepare_context.decode_github_file_content({"type": "file", "encoding": "none", "content": ""})

    def test_sanitize_untrusted_str(self):
        raw = "evil`path```json\n@bazelbuild/bcr-maintainers"
        sanitized = prepare_context.sanitize_untrusted_str(raw)
        self.assertNotIn("`", sanitized)
        self.assertNotIn("@bazelbuild", sanitized)
        self.assertNotIn("\n", sanitized)

    def test_routine_version_bump_by_maintainer_does_not_need_bcr_maintainer_review(self):
        meta, presubmit_text = self._create_module_on_main("foo", ("1.0.0",))
        head_meta = dict(meta)
        head_meta["versions"] = ["1.0.0", "1.1.0"]
        head_presubmit = presubmit_text.replace("7.x", "8.x")

        def fake_gh_api(endpoint, paginate=False, slurp=False):
            if endpoint == "repos/bazelbuild/bazel-central-registry/pulls/10":
                return {
                    "state": "open",
                    "draft": False,
                    "changed_files": 5,
                    "user": {"login": "alice"},
                    "head": {"sha": "a" * 40},
                }
            if "pulls/10/files" in endpoint:
                return [
                    [
                        {"filename": "modules/foo/metadata.json", "status": "modified"},
                        {"filename": "modules/foo/README.md", "status": "modified"},
                        {"filename": "modules/foo/1.1.0/MODULE.bazel", "status": "renamed"},
                        {"filename": "modules/foo/1.1.0/source.json", "status": "added"},
                        {"filename": "modules/foo/1.1.0/presubmit.yml", "status": "added"},
                    ]
                ]
            if "contents/modules/foo/metadata.json" in endpoint:
                return _b64_content(json.dumps(head_meta))
            if "contents/modules/foo/1.1.0/presubmit.yml" in endpoint:
                return _b64_content(head_presubmit)
            raise AssertionError(f"Unexpected endpoint: {endpoint}")

        env = {
            "REPOSITORY": "bazelbuild/bazel-central-registry",
            "EVENT_NAME": "pull_request_target",
            "EVENT_ACTION": "opened",
            "PR_NUMBER": "10",
            "GITHUB_OUTPUT": str(self.root / "output.txt"),
        }
        with patch.dict(os.environ, env, clear=False), patch.object(prepare_context, "gh_api", side_effect=fake_gh_api):
            rc = prepare_context.main()
            self.assertEqual(rc, 0)

        ctx = json.loads((self.root / ".gemini" / "context.json").read_text(encoding="utf-8"))
        self.assertFalse(ctx["needs_bcr_maintainer_review"])
        self.assertEqual(ctx["bcr_maintainer_review_reasons"], [])
        self.assertEqual(ctx["non_module_files"], [])
        self.assertEqual(ctx["mutated_existing_version_files"], [])
        self.assertEqual(len(ctx["modified_module_versions"]), 1)
        ver_info = ctx["modified_module_versions"][0]
        self.assertEqual(ver_info["module"], "foo")
        self.assertEqual(ver_info["version"], "1.1.0")
        self.assertEqual(ver_info["previous_version"], "1.0.0")
        self.assertFalse(ver_info["mutates_existing_version"])
        self.assertFalse(ver_info["presubmit_changed_beyond_platforms_or_bazel"])

    def test_existing_version_presubmit_allowed_but_module_bazel_mutation_flagged(self):
        self._create_module_on_main("foo", ("1.0.0",))
        changed_presubmit = (
            "matrix:\n"
            "  platform: [ubuntu2004]\n"
            "  bazel: [7.x]\n"
            "tasks:\n"
            "  verify_targets:\n"
            "    build_targets:\n"
            "      - '@foo//:other_target'\n"
        )

        def fake_gh_api(endpoint, paginate=False, slurp=False):
            if endpoint == "repos/bazelbuild/bazel-central-registry/pulls/11":
                return {
                    "state": "open",
                    "draft": False,
                    "changed_files": 2,
                    "user": {"login": "alice"},
                    "head": {"sha": "b" * 40},
                }
            if "pulls/11/files" in endpoint:
                return [
                    [
                        {"filename": "modules/foo/1.0.0/presubmit.yml", "status": "modified"},
                        {"filename": "modules/foo/1.0.0/MODULE.bazel", "status": "modified"},
                    ]
                ]
            if "contents/modules/foo/1.0.0/presubmit.yml" in endpoint:
                return _b64_content(changed_presubmit)
            raise AssertionError(f"Unexpected endpoint: {endpoint}")

        env = {
            "REPOSITORY": "bazelbuild/bazel-central-registry",
            "EVENT_NAME": "pull_request_target",
            "EVENT_ACTION": "opened",
            "PR_NUMBER": "11",
            "GITHUB_OUTPUT": str(self.root / "output.txt"),
        }
        with patch.dict(os.environ, env, clear=False), patch.object(prepare_context, "gh_api", side_effect=fake_gh_api):
            rc = prepare_context.main()
            self.assertEqual(rc, 0)

        ctx = json.loads((self.root / ".gemini" / "context.json").read_text(encoding="utf-8"))
        self.assertTrue(ctx["needs_bcr_maintainer_review"])
        # Only MODULE.bazel is flagged as violating the add-only policy, not presubmit.yml.
        self.assertEqual(ctx["mutated_existing_version_files"], ["modules/foo/1.0.0/MODULE.bazel"])
        self.assertTrue(ctx["modified_module_versions"][0]["mutates_existing_version"])
        self.assertTrue(ctx["modified_module_versions"][0]["presubmit_changed_beyond_platforms_or_bazel"])

    def test_draft_pr_skipped_on_automatic_but_runs_on_manual_trigger(self):
        def fake_gh_api(endpoint, paginate=False, slurp=False):
            return {
                "state": "open",
                "draft": True,
                "changed_files": 0,
                "user": {"login": "alice"},
                "head": {"sha": "c" * 40},
            }

        out_file = self.root / "output.txt"
        env = {
            "REPOSITORY": "bazelbuild/bazel-central-registry",
            "EVENT_NAME": "pull_request_target",
            "EVENT_ACTION": "opened",
            "PR_NUMBER": "12",
            "GITHUB_OUTPUT": str(out_file),
        }
        with patch.dict(os.environ, env, clear=False), patch.object(prepare_context, "gh_api", side_effect=fake_gh_api):
            self.assertEqual(prepare_context.main(), 0)
            self.assertIn("should_run=false", out_file.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
