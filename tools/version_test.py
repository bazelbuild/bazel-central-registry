#!/usr/bin/env python3
import unittest

from registry import Version

# Translated from:
# https://github.com/bazelbuild/bazel/blob/79a53def2ebbd9358450f739ea37bf70662e8614/src/test/java/com/google/devtools/build/lib/bazel/bzlmod/VersionTest.java#L39
class TestVersionCompare(unittest.TestCase):

  def testReleaseVersion(self):
    self.assertTrue(Version("2.0") > Version("1.0"))
    self.assertTrue(Version("2.0") > Version("1.9"))
    self.assertTrue(Version("11.0") > Version("3.0"))
    self.assertTrue(Version("1.0.1") > Version("1.0"))
    self.assertTrue(Version("1.0.0") > Version("1.0"))
    self.assertTrue(Version("1.0+build2") == Version("1.0+build3"))
    self.assertTrue(Version("1.0") > Version("1.0-pre"))
    self.assertTrue(Version("1.0") == Version("1.0+build-notpre"))

  def testReleaseVersionWithLetters(self):
    self.assertTrue(Version("1.0.patch.3") > Version("1.0"))
    self.assertTrue(Version("1.0.patch.3") > Version("1.0.patch.2"))
    self.assertTrue(Version("1.0.patch.3") < Version("1.0.patch.10"))
    self.assertTrue(Version("1.0.patch3") > Version("1.0.patch10"))
    self.assertTrue(Version("4") < Version("a"))
    self.assertTrue(Version("abc") < Version("abd"))

  def testPrereleaseVersion(self):
    self.assertTrue(Version("1.0-pre") > Version("1.0-are"))
    self.assertTrue(Version("1.0-3") > Version("1.0-2"))
    self.assertTrue(Version("1.0-pre") < Version("1.0-pre.foo"))
    self.assertTrue(Version("1.0-pre.3") > Version("1.0-pre.2"))
    self.assertTrue(Version("1.0-pre.10") > Version("1.0-pre.2"))
    self.assertTrue(Version("1.0-pre.10a") < Version("1.0-pre.2a"))
    self.assertTrue(Version("1.0-pre.99") < Version("1.0-pre.2a"))
    self.assertTrue(Version("1.0-pre.patch.3") < Version("1.0-pre.patch.4"))
    self.assertTrue(Version("1.0--") < Version("1.0----"))

if __name__ == '__main__':
  unittest.main()