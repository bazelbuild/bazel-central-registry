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
"""Unit tests for post_review.py."""

import json
import os
import pathlib
import tempfile
import unittest
from unittest.mock import MagicMock, patch

import post_review


class PostReviewTest(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmp_dir.name)
        self.old_cwd = os.getcwd()
        os.chdir(self.root)
        (self.root / ".gemini").mkdir()
        (self.root / "gemini-artifacts").mkdir()
        (self.root / ".gemini" / "context.json").write_text(
            json.dumps(
                {
                    "repository": "bazelbuild/bazel-central-registry",
                    "owner": "bazelbuild",
                    "repo": "bazel-central-registry",
                    "pull_request_number": 42,
                    "head_sha": "d" * 40,
                }
            ),
            encoding="utf-8",
        )

    def tearDown(self):
        os.chdir(self.old_cwd)
        self.tmp_dir.cleanup()

    def test_extract_review_json_repairs_unescaped_quotes_and_newlines(self):
        raw_response = (
            "Analysis complete.\n"
            "```json\n"
            "{\n"
            '  "should_post": true,\n'
            '  "skip_reason": null,\n'
            '  "body": "## 📋 Gemini BCR Review Summary\n'
            'Mismatches `"repository": ["github:leethomason/tinyxml2"]`.",\n'
            '  "comments": [\n'
            "    {\n"
            '      "path": "modules/tinyxml2/metadata.json",\n'
            '      "line": 2,\n'
            '      "side": "RIGHT",\n'
            '      "body": "🔴 Fix typo:\\n```suggestion\\n    \\"homepage\\": \\"https://github.com/leethomason/tinyxml2\\",\\n```"\n'
            "    }\n"
            "  ]\n"
            "}\n"
            "```"
        )
        parsed = post_review.extract_review_json(raw_response)
        self.assertIs(parsed["should_post"], True)
        self.assertIsNone(parsed["skip_reason"])
        self.assertIn('`"repository": ["github:leethomason/tinyxml2"]`', parsed["body"])
        self.assertEqual(len(parsed["comments"]), 1)

    def test_load_gemini_response_text_with_debug_prefix(self):
        inner = '```json\n{"should_post": false, "skip_reason": "Routine", "body": "", "comments": []}\n```'
        envelope = json.dumps({"response": inner, "stats": {}})
        (self.root / "gemini-artifacts" / "stdout.log").write_text(
            f"[DEBUG] Starting Gemini CLI\n{envelope}\n", encoding="utf-8"
        )
        self.assertEqual(post_review.load_gemini_response_text(), inner)

    def test_skip_when_should_post_is_false_or_string_false(self):
        for val in (False, "false", None):
            review_obj = {"should_post": val, "skip_reason": None, "body": "Ignored", "comments": []}
            (self.root / "gemini-artifacts" / "stdout.log").write_text(
                json.dumps({"response": json.dumps(review_obj)}), encoding="utf-8"
            )
            with patch.object(post_review, "gh_api_post") as mock_post:
                self.assertEqual(post_review.main(), 0)
                mock_post.assert_not_called()

    def test_caps_inline_comments_at_six_and_folds_overflow_and_non_diff_paths(self):
        comments = [
            {
                "path": "modules/foo/1.0.0/MODULE.bazel",
                "line": i,
                "side": "RIGHT",
                "body": f"Finding {i}",
            }
            for i in range(1, 8)
        ]
        comments.append(
            {
                "path": "modules/foo/0.9.0/MODULE.bazel",  # Not in PR diff
                "line": 3,
                "side": "RIGHT",
                "body": "Non-diff file finding",
            }
        )
        review_obj = {
            "should_post": True,
            "skip_reason": "",
            "body": "## Summary",
            "comments": comments,
        }
        (self.root / "gemini-artifacts" / "stdout.log").write_text(
            json.dumps({"response": json.dumps(review_obj)}), encoding="utf-8"
        )

        posted_payloads = []

        def fake_get(endpoint, paginate=False, slurp=False):
            return [[{"filename": "modules/foo/1.0.0/MODULE.bazel"}]]

        def fake_post(endpoint, payload):
            posted_payloads.append(payload)
            res = MagicMock()
            res.returncode = 0
            res.stdout = json.dumps({"html_url": "https://example.com/review/1"})
            res.stderr = ""
            return res

        with patch.object(post_review, "gh_api_get", side_effect=fake_get), patch.object(
            post_review, "gh_api_post", side_effect=fake_post
        ):
            self.assertEqual(post_review.main(), 0)

        self.assertEqual(len(posted_payloads), 1)
        payload = posted_payloads[0]
        self.assertEqual(payload["event"], "COMMENT")
        self.assertEqual(len(payload["comments"]), 6)
        self.assertIn("Finding 7", payload["body"])
        self.assertIn("Non-diff file finding", payload["body"])

    def test_retries_with_folded_comments_on_http_422(self):
        review_obj = {
            "should_post": True,
            "skip_reason": "",
            "body": "## Summary",
            "comments": [
                {
                    "path": "modules/foo/1.0.0/MODULE.bazel",
                    "line": 99,
                    "side": "RIGHT",
                    "body": "Context line comment",
                }
            ],
        }
        (self.root / "gemini-artifacts" / "stdout.log").write_text(
            json.dumps({"response": json.dumps(review_obj)}), encoding="utf-8"
        )

        posted_payloads = []

        def fake_get(endpoint, paginate=False, slurp=False):
            return [[{"filename": "modules/foo/1.0.0/MODULE.bazel"}]]

        def fake_post(endpoint, payload):
            posted_payloads.append(payload)
            res = MagicMock()
            if len(posted_payloads) == 1:
                res.returncode = 1
                res.stdout = '{"message": "Unprocessable Entity"}'
                res.stderr = "gh: Unprocessable Entity (HTTP 422)"
            else:
                res.returncode = 0
                res.stdout = json.dumps({"html_url": "https://example.com/review/2"})
                res.stderr = ""
            return res

        with patch.object(post_review, "gh_api_get", side_effect=fake_get), patch.object(
            post_review, "gh_api_post", side_effect=fake_post
        ):
            self.assertEqual(post_review.main(), 0)

        self.assertEqual(len(posted_payloads), 2)
        self.assertEqual(len(posted_payloads[0]["comments"]), 1)
        self.assertEqual(posted_payloads[1]["comments"], [])
        self.assertIn("Context line comment", posted_payloads[1]["body"])


if __name__ == "__main__":
    unittest.main()
