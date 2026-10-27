import json
import tarfile
import tempfile
import unittest
from pathlib import Path

from package_sources import package


class PackageSourcesTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.source = self.root / "source"
        for name in [
            "spconv/include/spconvlib/spconv/csrc/sparse/all/SpconvOps.h",
            "cumm/include/tensorview/tensor.h",
            "spconv/LICENSE",
            "cumm/LICENSE",
        ]:
            path = self.source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("source fixture\n")
        (self.source / "spconv-source.json").write_text(json.dumps({
            "spconv_commit": "263d6b47425ef843c82f997b12d8b714013d216c",
            "cumm_commit": "b8d83b6511b70746d04485d0d2ec00896b735430",
            "inference_only": True,
            "cuda_arch": "8.9",
            "cuda_version": "12.8",
        }))

    def test_preserves_sources_and_licenses_and_omits_host_cmake(self):
        (self.source / "spconv/CMakeLists.txt").write_text("/apollo/build\n")
        first = self.root / "first.tar.xz"
        second = self.root / "second.tar.xz"
        package(self.source, first)
        (self.source / "spconv/LICENSE").chmod(0o600)
        package(self.source, second)
        self.assertEqual(first.read_bytes(), second.read_bytes())
        with tarfile.open(first) as archive:
            names = archive.getnames()
            self.assertIn("cumm/LICENSE", names)
            self.assertNotIn("spconv/CMakeLists.txt", names)
            self.assertEqual(
                archive.extractfile("spconv/LICENSE").read(), b"source fixture\n"
            )

    def test_rejects_wrong_architecture(self):
        path = self.source / "spconv-source.json"
        manifest = json.loads(path.read_text())
        manifest["cuda_arch"] = "8.7"
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "cuda_arch"):
            package(self.source, self.root / "invalid.tar.xz")

    def test_rejects_symlink_and_host_path_in_source(self):
        link = self.source / "spconv/link.h"
        link.symlink_to(self.source / "spconv/LICENSE")
        with self.assertRaisesRegex(ValueError, "unsupported source entry"):
            package(self.source, self.root / "symlink.tar.xz")
        link.unlink()
        link.write_text('#include "/apollo/include/private.h"\n')
        with self.assertRaisesRegex(ValueError, "host-specific path"):
            package(self.source, self.root / "host-path.tar.xz")

    def test_refuses_existing_output(self):
        output = self.root / "existing.tar.xz"
        output.write_bytes(b"preserve")
        with self.assertRaises(FileExistsError):
            package(self.source, output)
        self.assertEqual(output.read_bytes(), b"preserve")


if __name__ == "__main__":
    unittest.main()
