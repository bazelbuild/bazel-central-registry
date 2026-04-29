import tempfile
import unittest

from pathlib import Path

from bcr_validation import BcrValidationException
from bcr_validation import resolve_source_root


class ResolveSourceRootTest(unittest.TestCase):
    def test_allows_relative_strip_prefix(self):
        with tempfile.TemporaryDirectory() as tmp:
            output_dir = Path(tmp) / "source_root"
            source_root = resolve_source_root(output_dir, "project-1.0.0")

        self.assertEqual(source_root, (output_dir / "project-1.0.0").resolve())

    def test_allows_empty_strip_prefix(self):
        with tempfile.TemporaryDirectory() as tmp:
            output_dir = Path(tmp) / "source_root"
            source_root = resolve_source_root(output_dir, "")

        self.assertEqual(source_root, output_dir.resolve())

    def test_rejects_absolute_strip_prefix(self):
        with tempfile.TemporaryDirectory() as tmp:
            output_dir = Path(tmp) / "source_root"
            with self.assertRaises(BcrValidationException):
                resolve_source_root(output_dir, "/")

    def test_rejects_parent_traversal_strip_prefix(self):
        with tempfile.TemporaryDirectory() as tmp:
            output_dir = Path(tmp) / "source_root"
            with self.assertRaises(BcrValidationException):
                resolve_source_root(output_dir, "../escape")


if __name__ == "__main__":
    unittest.main()
