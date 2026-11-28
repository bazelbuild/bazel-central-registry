import unittest

from add_boost_version import update_version_in_content


class UpdateVersionTest(unittest.TestCase):
    def test_updates_boost_dependencies_even_when_versions_differ(self):
        content = '''\
module(name = "boost.example", version = "1.90.0.bcr.2")
bazel_dep(name = "boost", version = "1.90.0.bcr.1")
bazel_dep(
    name = "boost.core",
    version = "1.89.0.bcr.4",
)
bazel_dep(name = "other", version = "1.90.0.bcr.1")
'''
        self.assertEqual(
            update_version_in_content(content, "1.90.0.bcr.2", "1.92.0"),
            '''\
module(name = "boost.example", version = "1.92.0")
bazel_dep(name = "boost", version = "1.92.0")
bazel_dep(
    name = "boost.core",
    version = "1.92.0",
)
bazel_dep(name = "other", version = "1.90.0.bcr.1")
''',
        )


if __name__ == "__main__":
    unittest.main()
