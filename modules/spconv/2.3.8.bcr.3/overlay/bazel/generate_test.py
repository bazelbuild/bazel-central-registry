import hashlib
import tempfile
import unittest
from pathlib import Path

from generate import read_manifest, validate_tree


class GenerationContractTest(unittest.TestCase):
    def test_exact_files_and_contents_ignoring_only_cmake(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "kernel.cu").write_bytes(b"kernel")
            (root / "CMakeLists.txt").write_text("unused host paths")
            expected = {"kernel.cu": hashlib.sha256(b"kernel").hexdigest()}
            validate_tree(root, expected)
            (root / "kernel.cu").write_bytes(b"drift")
            with self.assertRaisesRegex(ValueError, "content changed"):
                validate_tree(root, expected)

    def test_missing_and_unexpected_files_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "new.h").write_bytes(b"")
            with self.assertRaisesRegex(ValueError, "missing=.*old.h.*extra=.*new.h"):
                validate_tree(root, {"old.h": hashlib.sha256(b"").hexdigest()})

    def test_manifest_rejects_escape_and_non_source(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "outputs.bzl"
            for name in ("../escape.h", "/absolute.h", "kernel.so"):
                path.write_text('OUTPUTS = {"' + name + '": ""}')
                with self.subTest(name=name), self.assertRaises(ValueError):
                    read_manifest(path)


if __name__ == "__main__":
    unittest.main()
