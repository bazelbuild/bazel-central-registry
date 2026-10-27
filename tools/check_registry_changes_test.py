"""Regression tests for the private registry's publication policy."""

import base64
import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from check_registry_changes import check_changes, consumer_versions


class RegistryChangesTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.run_git("init", "-q")
        self.run_git("config", "user.name", "Registry test")
        self.run_git("config", "user.email", "test@example.invalid")
        self.add_version("1.0")
        self.commit()

    def run_git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.root), *args])

    def commit(self):
        self.run_git("add", ".")
        self.run_git("commit", "-qm", "test fixture")

    def add_version(self, version):
        module = self.root / "modules/example"
        path = module / version
        path.mkdir(parents=True)
        metadata_path = module / "metadata.json"
        metadata = (
            json.loads(metadata_path.read_text())
            if metadata_path.exists()
            else {
                "maintainers": [{"github": "example"}],
                "versions": [],
                "yanked_versions": {},
            }
        )
        metadata["versions"].append(version)
        metadata_path.write_text(json.dumps(metadata))
        (path / "MODULE.bazel").write_text(f'module(name = "example", version = "{version}")\n')
        (path / "source.json").write_text(
            json.dumps(
                {
                    "url": "https://example.invalid/source.tar.gz",
                    "integrity": "sha256-example",
                }
            )
        )
        (path / "presubmit.yml").write_text("tasks: {}\n")
        return path

    def test_selects_untracked_new_versions(self):
        self.add_version("1.1")
        self.assertEqual(["example@1.1"], check_changes(self.root, "HEAD"))

    def test_rejects_edit_delete_or_new_file_in_published_version(self):
        path = self.root / "modules/example/1.0"
        module = path / "MODULE.bazel"
        original = module.read_text()
        module.write_text("changed")
        with self.assertRaisesRegex(ValueError, "immutable"):
            check_changes(self.root, "HEAD")
        module.unlink()
        with self.assertRaisesRegex(ValueError, "immutable"):
            check_changes(self.root, "HEAD")
        module.write_text(original)
        (path / "new.patch").write_text("new")
        with self.assertRaisesRegex(ValueError, "immutable"):
            check_changes(self.root, "HEAD")

    def test_metadata_can_yank_but_not_remove_versions(self):
        self.add_version("1.1")
        self.commit()
        path = self.root / "modules/example/metadata.json"
        metadata = json.loads(path.read_text())
        metadata["yanked_versions"] = {"1.0": "Superseded"}
        path.write_text(json.dumps(metadata))
        self.assertEqual([], check_changes(self.root, "HEAD"))
        metadata["versions"].remove("1.0")
        path.write_text(json.dumps(metadata))
        with self.assertRaisesRegex(ValueError, "cannot remove"):
            check_changes(self.root, "HEAD")

    def test_rejects_missing_maintainer_and_bad_patch_integrity(self):
        path = self.add_version("1.1")
        source_path = path / "source.json"
        source = json.loads(source_path.read_text())
        (path / "patches").mkdir()
        patch = path / "patches/module.patch"
        patch.write_bytes(b"patch")
        source["patches"] = {"module.patch": "sha256-invalid"}
        source_path.write_text(json.dumps(source))
        with self.assertRaisesRegex(ValueError, "Integrity mismatch"):
            check_changes(self.root, "HEAD")
        source["patches"]["module.patch"] = (
            "sha256-" + base64.b64encode(hashlib.sha256(patch.read_bytes()).digest()).decode()
        )
        source_path.write_text(json.dumps(source))
        self.assertEqual(["example@1.1"], check_changes(self.root, "HEAD"))
        metadata_path = path.parent / "metadata.json"
        metadata = json.loads(metadata_path.read_text())
        metadata["maintainers"] = []
        metadata_path.write_text(json.dumps(metadata))
        with self.assertRaisesRegex(ValueError, "maintainer"):
            check_changes(self.root, "HEAD")


class ConsumerMatrixTest(unittest.TestCase):
    def test_expands_supported_versions_without_other_platform_tasks(self):
        spec = {
            "matrix": {"platform": ["ubuntu2204", "windows"], "bazel": ["7.x", "8.x"]},
            "tasks": {
                "matrix": {"platform": "${{ platform }}", "bazel": "${{ bazel }}"},
                "mac": {"platform": "macos", "bazel": "9.x"},
            },
        }
        self.assertEqual(["7.6.2", "8.8.1"], consumer_versions(spec))

    def test_preserves_concrete_versions_and_rejects_missing_coverage(self):
        self.assertEqual(
            ["8.8.1"],
            consumer_versions({"tasks": {"a": {"platform": "ubuntu2204", "bazel": "8.8.1"}}}),
        )
        for tasks in ({}, {"a": {"platform": "windows", "bazel": "8.x"}}, {"a": {"platform": "ubuntu2204"}}):
            with self.subTest(tasks=tasks), self.assertRaisesRegex(ValueError, "required"):
                consumer_versions({"tasks": tasks})


if __name__ == "__main__":
    unittest.main()
