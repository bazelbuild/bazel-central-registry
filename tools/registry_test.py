#!/usr/bin/env python3
import pathlib
import tempfile
import unittest

from registry import RegistryClient, RegistryException


class TestRegistryClient(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp_dir.cleanup)
        self.registry_root = pathlib.Path(self.tmp_dir.name)
        self.registry = RegistryClient(self.registry_root)

    def test_get_patch_file_path_allows_relative_path(self):
        patch_file = self.registry.get_patch_file_path("foo", "1.0.0", "fix.patch")

        self.assertEqual(
            patch_file,
            self.registry_root.resolve() / "modules" / "foo" / "1.0.0" / "patches" / "fix.patch",
        )

    def test_get_patch_file_path_allows_nested_relative_path(self):
        patch_file = self.registry.get_patch_file_path("foo", "1.0.0", "subdir/fix.patch")

        self.assertEqual(
            patch_file,
            self.registry_root.resolve() / "modules" / "foo" / "1.0.0" / "patches" / "subdir" / "fix.patch",
        )

    def test_get_patch_file_path_rejects_absolute_path(self):
        patch_file = pathlib.Path(self.tmp_dir.name) / "outside.patch"

        with self.assertRaisesRegex(RegistryException, "must point inside"):
            self.registry.get_patch_file_path("foo", "1.0.0", str(patch_file))

    def test_get_patch_file_path_rejects_parent_traversal(self):
        with self.assertRaisesRegex(RegistryException, "must point inside"):
            self.registry.get_patch_file_path("foo", "1.0.0", "../outside.patch")


if __name__ == "__main__":
    unittest.main()
