import unittest

from unittest.mock import MagicMock
from registry import RegistryClient
from module_selector import select_modules


class TestSelectModules(unittest.TestCase):
    def setUp(self):
        # Create a mock registry client
        self.registry = RegistryClient("/fake")
        self.registry.get_all_modules = MagicMock(return_value=["foo_module", "bar_module", "baz_module", "qux_module"])
        self.registry.get_module_versions = MagicMock(side_effect=self.mock_get_module_versions)

    def mock_get_module_versions(self, module_name):
        versions = {
            "foo_module": [("foo_module", "1.0.0"), ("foo_module", "1.1.0"), ("foo_module", "1.2.0")],
            "bar_module": [("bar_module", "2.0.0"), ("bar_module", "2.1.0")],
            "baz_module": [("baz_module", "0.9.0"), ("baz_module", "1.0.0")],
            "qux_module": [("qux_module", "3.0.0")],
        }
        return versions.get(module_name, [])

    def test_select_specific_version(self):
        selections = ["foo_module@1.1.0"]
        result = select_modules(self.registry, selections)
        expected = ["foo_module@1.1.0"]
        self.assertEqual(result, expected)

    def test_select_latest_version(self):
        selections = ["foo_module@latest"]
        result = select_modules(self.registry, selections)
        expected = ["foo_module@1.2.0"]
        self.assertEqual(result, expected)

    def test_select_version_greater_than(self):
        selections = ["foo_module@>1.0.0"]
        result = select_modules(self.registry, selections)
        expected = ["foo_module@1.1.0", "foo_module@1.2.0"]
        self.assertEqual(result, expected)

    def test_select_version_less_than_or_equal(self):
        selections = ["bar_module@<=2.0.0"]
        result = select_modules(self.registry, selections)
        expected = ["bar_module@2.0.0"]
        self.assertEqual(result, expected)

    def test_select_with_wildcard(self):
        selections = ["ba*_module@latest"]
        result = select_modules(self.registry, selections)
        expected = ["bar_module@2.1.0", "baz_module@1.0.0"]
        self.assertEqual(sorted(result), sorted(expected))

    def test_select_random_percentage(self):
        selections = ["foo_module@>0"]
        result = select_modules(self.registry, selections, random_percentage=50)
        possible_versions = ["foo_module@1.0.0", "foo_module@1.1.0", "foo_module@1.2.0"]
        # Ensure that the result is a subset of possible_versions
        self.assertTrue(set(result).issubset(set(possible_versions)))
        # Check that the number of selected modules is correct
        expected_count = max(1, (50 * len(possible_versions)) // 100)
        self.assertEqual(len(result), expected_count)

    def test_invalid_selection_pattern_missing_at(self):
        selections = ["foo_module"]
        with self.assertRaises(ValueError):
            select_modules(self.registry, selections)

    def test_invalid_selection_pattern_empty_module(self):
        selections = ["@1.0.0"]
        with self.assertRaises(ValueError):
            select_modules(self.registry, selections)

    def test_invalid_version_not_found(self):
        selections = ["foo_module@9.9.9"]
        with self.assertRaises(ValueError):
            select_modules(self.registry, selections)

    def test_no_matching_modules(self):
        selections = ["nonexistent_module@latest"]
        with self.assertRaises(ValueError):
            select_modules(self.registry, selections)

    def test_empty_selections(self):
        selections = []
        with self.assertRaises(ValueError):
            select_modules(self.registry, selections)


if __name__ == "__main__":
    unittest.main()
