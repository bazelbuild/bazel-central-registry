#!/usr/bin/env python3
import pathlib
import tempfile
import unittest

from registry import (
    ALLOWED_DOWNLOAD_SCHEMES,
    RegistryClient,
    RegistryException,
    _validate_download_url,
)


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


class TestValidateDownloadUrl(unittest.TestCase):
    """`_validate_download_url` is the choke point that prevents PR-supplied
    URLs (`source.url`, `mirror_urls`, patch URLs) from triggering local-file
    reads or non-HTTP protocol abuse via `urllib.request.urlopen`.
    """

    def test_https_is_allowed(self):
        parts = _validate_download_url("https://example.com/archive.tar.gz")
        self.assertEqual(parts.scheme, "https")

    def test_http_is_allowed(self):
        # HTTP is intentionally permitted because legacy `mirror_urls` exist.
        parts = _validate_download_url("http://mirrors.example.com/x.tar.gz")
        self.assertEqual(parts.scheme, "http")

    def test_file_scheme_is_rejected(self):
        # The motivating case: a PR-submitted `source.json` whose `url` reads
        # local files from the validation runner.
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("file:///etc/passwd")

    def test_proc_environ_file_scheme_is_rejected(self):
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("file:///proc/self/environ")

    def test_dev_null_file_url_is_allowed(self):
        # `file:///dev/null` is an allow-listed benign exception used by
        # `tools/update_integrity_test.sh`. It always reads as empty bytes
        # so it has no exfiltration value (see comment on `_BENIGN_FILE_URLS`
        # in `registry.py`).
        parts = _validate_download_url("file:///dev/null")
        self.assertEqual(parts.scheme, "file")
        self.assertEqual(parts.path, "/dev/null")

    def test_other_file_url_is_rejected_even_with_similar_path(self):
        # Make sure the allow-list is exact match, not a prefix/substring
        # match. `file:///dev/null/../etc/passwd` MUST still be rejected.
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("file:///dev/null/../etc/passwd")
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("file:///dev/nullx")

    def test_ftp_scheme_is_rejected(self):
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("ftp://example.com/archive.tar.gz")

    def test_gopher_scheme_is_rejected(self):
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("gopher://example.com:70/_test")

    def test_data_scheme_is_rejected(self):
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("data:text/plain;base64,SGVsbG8=")

    def test_jar_scheme_is_rejected(self):
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("jar:file:///tmp/x.jar!/inner")

    def test_empty_scheme_is_rejected(self):
        # `urllib.parse.urlsplit` returns scheme="" for raw paths like
        # "/etc/passwd" or "example.com/archive.tar.gz".
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("/etc/passwd")
        with self.assertRaisesRegex(RegistryException, "not allowed"):
            _validate_download_url("example.com/archive.tar.gz")

    def test_uppercase_scheme_is_normalised(self):
        # `urlsplit` lowercases the scheme; both forms map to "https".
        parts = _validate_download_url("HTTPS://example.com/x.tar.gz")
        self.assertEqual(parts.scheme, "https")

    def test_allowlist_is_minimal(self):
        # If this test fails, audit the new scheme: it MUST be safe to
        # invoke `urllib.request.urlopen` on attacker-controlled URLs of
        # this scheme. See the comment on `ALLOWED_DOWNLOAD_SCHEMES`.
        self.assertEqual(ALLOWED_DOWNLOAD_SCHEMES, frozenset({"http", "https"}))


if __name__ == "__main__":
    unittest.main()
