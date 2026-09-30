"""Smoke test for the MarkupSafe Bazel module."""

import unittest

from markupsafe import Markup, escape


class MarkupSafeTest(unittest.TestCase):
    def test_escape(self):
        self.assertEqual(str(escape("<script>")), "&lt;script&gt;")

    def test_markup_is_not_escaped_again(self):
        self.assertEqual(str(Markup("<b>") + escape("<i>")), "<b>&lt;i&gt;")


if __name__ == "__main__":
    unittest.main()
