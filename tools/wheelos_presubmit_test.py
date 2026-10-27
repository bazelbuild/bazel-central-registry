"""Tests for pinned, cache-preserving registry consumer execution."""

import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from wheelos_presubmit import (
    GitRegistryBaseline,
    prepare_test_module,
    run_tasks,
    validation_exceptions,
)


class ConsumerTest(unittest.TestCase):
    def test_only_commit_and_version_tag_archives_get_url_classification_waiver(self):
        prefix = "https://github.com/traveller59/spconv/archive/"
        commit = "263d6b47425ef843c82f997b12d8b714013d216c"
        for extension in (".tar.gz", ".zip"):
            self.assertEqual(
                ["presubmit_yml", "url_stability"],
                validation_exceptions(prefix + commit + extension),
            )
            for tag in ("1.0.6", "v0.1.3"):
                with self.subTest(tag=tag, extension=extension):
                    self.assertEqual(
                        ["presubmit_yml", "url_stability"],
                        validation_exceptions(prefix + "refs/tags/" + tag + extension),
                    )
        for url in (
            prefix + "main.tar.gz",
            prefix + "refs/heads/1.0.6.tar.gz",
            prefix + "refs/tags/latest.tar.gz",
            prefix + "refs/tags/v0.1.3.tar.gz?download=1",
            prefix + "refs/tags/v0.1.3/extra.tar.gz",
            prefix + commit[:8] + ".tar.gz",
            prefix + commit + ".tar.gz?ref=main",
            prefix.replace("https:", "http:") + commit + ".tar.gz",
            "https://example.invalid/" + commit + ".tar.gz",
            None,
        ):
            with self.subTest(url=url):
                self.assertEqual(["presubmit_yml"], validation_exceptions(url))

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    @patch("wheelos_presubmit.subprocess.run")
    def test_selects_platform_version_and_inherits_build_flags(self, run):
        tasks = {
            "matching": {
                "platform": "ubuntu2204",
                "bazel": "8.x",
                "build_flags": ["--compilation_mode=opt"],
                "test_flags": ["--test_arg=example"],
                "build_targets": ["@example//:library"],
                "test_targets": ["@example//:test"],
            },
            "other": {
                "platform": "macos",
                "bazel": "8.x",
                "build_targets": ["@example//:mac"],
            },
        }
        run_tasks(self.root, tasks, "8.8.1", "bazelisk", self.root / "cache")
        self.assertEqual(2, run.call_count)
        build, test = run.call_args_list
        self.assertIn("--compilation_mode=opt", build.args[0])
        self.assertIn("--compilation_mode=opt", test.args[0])
        self.assertIn("--test_arg=example", test.args[0])
        self.assertIn("--flaky_test_attempts=1", test.args[0])
        self.assertEqual("8.8.1", test.kwargs["env"]["USE_BAZEL_VERSION"])
        self.assertIn("--nosystem_rc", test.args[0])
        self.assertIn("--nohome_rc", test.args[0])
        self.assertIn("--batch", test.args[0])
        self.assertNotIn("--override_module", (self.root / ".bazelrc").read_text())

    def test_missing_platform_or_bazel_fails_instead_of_skipping(self):
        with self.assertRaisesRegex(ValueError, "No Ubuntu"):
            run_tasks(self.root, {}, "8.8.1", "bazelisk", self.root / "cache")

    def test_attestation_baseline_comes_from_previous_commit_not_worktree(self):
        module = self.root / "modules/example"
        version = module / "1.0"
        version.mkdir(parents=True)
        metadata = module / "metadata.json"
        metadata.write_text(json.dumps({"versions": ["1.0"]}))
        (version / "attestations.json").write_text('{"source": "attested"}')
        command = ["git", "-C", str(self.root)]
        subprocess.run([*command, "init", "-q"], check=True)
        subprocess.run([*command, "add", "."], check=True)
        subprocess.run(
            [
                *command,
                "-c",
                "user.name=Registry test",
                "-c",
                "user.email=test@example.invalid",
                "commit",
                "-qm",
                "fixture",
            ],
            check=True,
        )
        metadata.write_text(json.dumps({"versions": ["1.0", "1.1"]}))
        baseline = GitRegistryBaseline(self.root, "HEAD")
        previous = baseline.get_latest_module_version("example")
        self.assertEqual("1.0", previous.version)
        self.assertEqual({"source": "attested"}, previous.attestations())
        self.assertIsNone(baseline.get_latest_module_version("new"))

    @patch("wheelos_presubmit.subprocess.check_output")
    def test_test_module_uses_source_fetched_by_pinned_consumer(self, output):
        base = self.root / "output"
        source = base / "external/example+/test_module"
        source.mkdir(parents=True)
        (source / "MODULE.bazel").write_text('bazel_dep(name="example")')
        output.side_effect = [
            json.dumps({"example": "example+"}),
            str(base) + "\n",
        ]
        result = prepare_test_module(
            self.root,
            self.root / "module_src",
            "example",
            {"module_path": "test_module"},
            "8.8.1",
            "bazelisk",
        )
        self.assertTrue((result / "MODULE.bazel").is_file())
        self.assertEqual(2, output.call_count)
        for call in output.call_args_list:
            self.assertEqual("8.8.1", call.kwargs["env"]["USE_BAZEL_VERSION"])
            self.assertNotIn("vendor", call.args[0])


if __name__ == "__main__":
    unittest.main()
