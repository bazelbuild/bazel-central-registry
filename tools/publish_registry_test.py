"""Tests for add-only object publication and metadata ordering."""

import json
import tempfile
import unittest
from pathlib import Path

from publish_registry import plan_uploads, validate_publication


class PublicationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "bazel_registry.json").write_text("{}")
        version = self.root / "modules/example/1.0"
        version.mkdir(parents=True)
        (version / "MODULE.bazel").write_text("module()")
        (version.parent / "metadata.json").write_text(json.dumps({"versions": ["1.0"]}))

    def test_plans_versions_before_metadata_and_ignores_tooling(self):
        (self.root / "secret-tooling").write_text("not registry content")
        immutable, mutable = plan_uploads(self.root, set(), lambda key: self.fail(key))
        self.assertEqual(["modules/example/1.0/MODULE.bazel"], [key for key, _ in immutable])
        self.assertEqual(
            ["bazel_registry.json", "modules/example/metadata.json"],
            [key for key, _ in mutable],
        )

    def test_identical_objects_are_not_republished(self):
        key = "modules/example/1.0/MODULE.bazel"
        immutable, _ = plan_uploads(self.root, {key}, lambda _: b"module()")
        self.assertEqual([], immutable)

    def test_existing_untouched_objects_are_not_downloaded_or_uploaded(self):
        keys = {
            "bazel_registry.json",
            "modules/example/1.0/MODULE.bazel",
            "modules/example/metadata.json",
        }
        immutable, mutable = plan_uploads(
            self.root,
            keys,
            lambda key: self.fail(f"Unnecessary download: {key}"),
            candidates=set(),
        )
        self.assertEqual(([], []), (immutable, mutable))

    def test_absent_remote_objects_cannot_escape_validation_as_unchanged_files(self):
        immutable, mutable = plan_uploads(
            self.root,
            set(),
            lambda key: self.fail(key),
            candidates=set(),
        )
        with self.assertRaisesRegex(ValueError, "example@1.0"):
            validate_publication(immutable, mutable, [], set(), lambda key: self.fail(key))

    def test_rejects_conflicting_published_objects(self):
        with self.assertRaisesRegex(ValueError, "overwrite"):
            plan_uploads(self.root, {"modules/example/1.0/MODULE.bazel"}, lambda _: b"old")

    def test_rejects_metadata_removal_and_missing_remote_versions(self):
        with self.assertRaisesRegex(ValueError, "remove published versions"):
            plan_uploads(
                self.root,
                {"modules/example/metadata.json"},
                lambda _: b'{"versions": ["0.9", "1.0"]}',
            )
        with self.assertRaisesRegex(ValueError, "absent locally"):
            plan_uploads(
                self.root,
                {"modules/example/0.9/MODULE.bazel"},
                lambda key: self.fail(key),
            )

    def test_requires_consumer_validation_for_every_new_upload(self):
        immutable, mutable = plan_uploads(self.root, set(), lambda key: self.fail(key))
        with self.assertRaisesRegex(ValueError, "example@1.0"):
            validate_publication(immutable, mutable, [], set(), lambda key: self.fail(key))
        validate_publication(immutable, mutable, ["example@1.0"], set(), lambda key: self.fail(key))

    def test_partial_previous_upload_cannot_bypass_metadata_validation(self):
        key = "modules/example/1.0/MODULE.bazel"
        immutable, mutable = plan_uploads(self.root, {key}, lambda _: b"module()")
        self.assertEqual([], immutable)
        with self.assertRaisesRegex(ValueError, "example@1.0"):
            validate_publication(immutable, mutable, [], {key}, lambda key: self.fail(key))


if __name__ == "__main__":
    unittest.main()
