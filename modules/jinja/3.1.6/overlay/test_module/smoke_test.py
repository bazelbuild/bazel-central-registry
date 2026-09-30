"""Smoke test for the Jinja Bazel module."""

import unittest

from jinja2 import Environment, Template


class JinjaTest(unittest.TestCase):
    def test_render(self):
        self.assertEqual(Template("Hello {{ name }}!").render(name="Bazel"), "Hello Bazel!")

    def test_autoescape_uses_markupsafe(self):
        env = Environment(autoescape=True)
        self.assertEqual(env.from_string("{{ value }}").render(value="<b>"), "&lt;b&gt;")


if __name__ == "__main__":
    unittest.main()
