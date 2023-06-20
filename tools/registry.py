#!/usr/bin/env python3
#
# Copyright 2021 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# pylint: disable=missing-function-docstring
# pylint: disable=too-many-instance-attributes
# pylint: disable=unspecified-encoding
# pylint: disable=invalid-name
"""Tool classes to handle a Bazel registry"""

import base64
import difflib
import functools
import hashlib
import json
import netrc
import pathlib
import re
import shutil
import urllib.parse
import urllib.request
import yaml

GREEN = "\x1b[32m"
RESET = "\x1b[0m"


def log(msg):
  print(f"{GREEN}INFO: {RESET}{msg}")


def download(url):
  parts = urllib.parse.urlparse(url)
  try:
    authenticators = netrc.netrc().authenticators(parts.netloc)
  except FileNotFoundError:
    authenticators = None
  if authenticators != None:
    (login, _, password) = authenticators
    req = urllib.request.Request(url)
    creds = base64.b64encode(str.encode('%s:%s' % (login, password))).decode()
    req.add_header("Authorization", "Basic %s" % creds)
  else:
    req = url

  with urllib.request.urlopen(req) as response:
    return response.read()

def download_file(url, file):
  with open(file, "wb") as f:
      f.write(download(url))

def read(path):
  with open(path, "rb") as file:
    return file.read()


def integrity(data):
  hash_value = hashlib.sha256(data)
  return "sha256-" + base64.b64encode(hash_value.digest()).decode()


def json_dump(file, data, sort_keys=True):
  with open(file, "w") as f:
    json.dump(data, f, indent=4, sort_keys=sort_keys)
    f.write("\n")

# Translated from:
# https://github.com/bazelbuild/bazel/blob/79a53def2ebbd9358450f739ea37bf70662e8614/src/main/java/com/google/devtools/build/lib/bazel/bzlmod/Version.java#L58
@functools.total_ordering
class Version:

  @functools.total_ordering
  class Identifier:
    def __init__(self, s):
      if not s:
        raise RegistryException("identifier is empty")
      self.val = int(s) if s.isnumeric() else s

    def __eq__(self, other):
      if type(self.val) != type(other.val):
        return False
      return self.val == other.val

    def __lt__(self, other):
      if type(self.val) != type(other.val):
        return type(self.val) == int
      return self.val < other.val

  @staticmethod
  def convert_to_identifiers(s):
    if s == None:
      return None
    return [Version.Identifier(i) for i in s.split(".")]

  def __init__(self, version_str):
    PATTERN = re.compile(r"^([a-zA-Z0-9.]+)(?:-([a-zA-Z0-9.-]+))?(?:\+[a-zA-Z0-9.-]+)?$")
    m = PATTERN.match(version_str)
    if not m:
      raise RegistryException(f"`{version_str}` is not a valid version")
    self.release = Version.convert_to_identifiers(m.groups()[0])
    self.prerelease = Version.convert_to_identifiers(m.groups()[1])

  def __eq__(self, other):
    return (self.release, self.prerelease) == (other.release, other.prerelease)

  def __lt__(self, other):
    if self.release != other.release:
      return self.release < other.release
    if self.prerelease == None:
      return False
    if other.prerelease == None:
      return True
    return self.prerelease < other.prerelease


class Module:
  """A class to represent all information of a Bazel module."""

  def __init__(self, name=None, version=None, compatibility_level=1):
    self.name = name
    self.version = version
    self.compatibility_level = compatibility_level
    self.module_dot_bazel = None
    self.url = None
    self.strip_prefix = None
    self.deps = []
    self.patches = []
    self.patch_strip = 0
    self.build_file = None
    self.presubmit_yml = None
    self.build_targets = []
    self.test_module_path = None
    self.test_module_build_targets = []
    self.test_module_test_targets = []

  def add_dep(self, module_name, version):
    self.deps.append((module_name, version))
    return self

  def set_module_dot_bazel(self, module_dot_bazel):
    self.module_dot_bazel = module_dot_bazel
    return self

  def set_source(self, url, strip_prefix=None):
    self.url = url
    self.strip_prefix = strip_prefix
    return self

  def add_patch(self, patch_file):
    self.patches.append(patch_file)
    return self

  def set_patch_strip(self, patch_strip):
    self.patch_strip = patch_strip
    return self

  def set_build_file(self, build_file):
    self.build_file = build_file
    return self

  def set_presubmit_yml(self, presubmit_yml):
    self.presubmit_yml = presubmit_yml
    return self

  def add_build_target(self, target):
    if not target.startswith("@" + self.name):
      target = "@" + self.name + target
    self.build_targets.append(target)
    return self

  def add_test_module_build_target(self, target):
    self.test_module_build_targets.append(target)
    return self

  def add_test_module_test_target(self, target):
    self.test_module_test_targets.append(target)
    return self

  def dump(self, file):
    json_dump(file, self.__dict__)

  def from_json(self, file):
    with open(file) as f:
      self.__dict__ = json.load(f)


class RegistryException(Exception):
  """
  Raised whenever something goes wrong with modifying the registry.
  """


class RegistryClient:
  """A class to help create a Bazel registry."""

  _MODULE_BAZEL = """
module(
    name = "{0}",
    version = "{1}",
    compatibility_level = {2},
)
""".strip()

  def __init__(self, root):
    self.root = pathlib.Path(root)

  def get_all_modules(self):
    modules_dir = self.root.joinpath("modules")
    return [path.name for path in modules_dir.iterdir()]

  def get_module_versions(self, module_name):
    module_versions = []
    metadata = self.get_metadata(module_name)
    for version in metadata["versions"]:
      module_versions.append((module_name, version))
    return module_versions

  def get_all_module_versions(self):
    module_versions = []
    for module_name in self.get_all_modules():
      module_versions.extend(self.get_module_versions(module_name))
    return module_versions

  def get_metadata(self, module_name):
    metadata_path = self.root.joinpath("modules", module_name,
                                       "metadata.json")
    return json.load(metadata_path.open())

  def get_source(self, module_name, version):
    source_path = self.root.joinpath("modules", module_name, version,
                                     "source.json")
    return json.load(source_path.open())

  def get_source_path(self, module_name, version):
    return self.root.joinpath("modules", module_name, version,
                              "source.json")

  def get_presubmit_yml_path(self, module_name, version):
    return self.root.joinpath("modules", module_name, version,
                              "presubmit.yml")

  def get_patch_file_path(self, module_name, version, patch_name):
    return self.root.joinpath("modules", module_name, version,
                              "patches", patch_name)

  def get_module_dot_bazel_path(self, module_name, version):
    return self.root.joinpath("modules", module_name, version,
                              "MODULE.bazel")

  def contains(self, module_name, version=None):
    """
    Check if the registry contains a module or a specific version of a
    module by verifying if the directory exists.
    """
    dir_path = self.root.joinpath("modules", module_name)
    if version:
      dir_path = dir_path.joinpath(version)
    return dir_path.is_dir()

  def init_module(self, module_name, maintainers, homepage, source_repository = ""):
    """
    Initialize a module, create the directory and metadata.json file.

    Parameters
    ----------
    module_name : str
        The module name
    maintainers : list of maps of string -> string
        The maintainer information, eg
         [{"name": "John", "email": "john@guugoo.com"},
          {"name": "Yun", "github": "meteorcloudy"}]
    homepage : str
        A URL to the project's homepage

    """
    p = self.root.joinpath("modules", module_name)
    p.mkdir(parents=True, exist_ok=True)

    # Create metadata.json file
    metadata = {
        "maintainers": maintainers,
        "homepage": homepage,
        "repository": [source_repository] if source_repository else [],
        "versions": [],
        "yanked_versions": {},
    }
    json_dump(p.joinpath("metadata.json"), metadata)

  def add(self, module, override=False):
    """
    Add a new module version, the module must be already initialized

    Parameters
    ----------
    module : Module
        A Module instance containing information of the module version to
        be added
    override : Whether to override existing module
    """
    # Check if the module version already exists
    if self.contains(module.name, module.version):
      if override:
        log("Overridding module '%s' at version '%s'..." %
            (module.name, module.version))
        self.delete(module.name, module.version)
      else:
        raise RegistryException(
            f"Version {module.version} for module {module.name} already exists.")

    p = self.root.joinpath("modules", module.name, module.version)
    p.mkdir()

    # Create MODULE.bazel
    module_dot_bazel = p.joinpath("MODULE.bazel")
    if module.module_dot_bazel:
      # TODO(pcloudy): Sanity check the given MODULE.bazel
      #   - module name and version should match the specified values
      #   - no override is used
      shutil.copy(module.module_dot_bazel, module_dot_bazel)
    else:
      deps = "\n".join(
          f"bazel_dep(name = \"{name}\", version = \"{version}\")"
          for name, version in module.deps)
      with module_dot_bazel.open("w") as f:
        f.write(self._MODULE_BAZEL.format(
            module.name, module.version,
            module.compatibility_level))
        if deps:
          f.write("\n")
          f.write(deps)
        f.write("\n")

    # Create source.json & copy patch files to the registry
    source = {
        "url": module.url,
        "integrity": integrity(download(module.url)),
    }
    if module.strip_prefix:
      source["strip_prefix"] = module.strip_prefix

    patch_dir = p.joinpath("patches")
    if module.patches or module.build_file:
      patch_dir.mkdir()
      source["patches"] = {}
      source["patch_strip"] = module.patch_strip

    if module.patches:
      for s in module.patches:
        patch = pathlib.Path(s)
        source["patches"][patch.name] = integrity(read(patch))
        shutil.copy(patch, patch_dir)

    # Turn additional BUILD file into a patch
    if module.build_file:
      build_file_content = pathlib.Path(module.build_file).open().readlines()
      build_file = "a/" * module.patch_strip + "BUILD.bazel"
      patch_content = difflib.unified_diff(
          [], build_file_content, "/dev/null", build_file)
      patch_name = "add_build_file.patch"
      patch = patch_dir.joinpath(patch_name)
      with patch.open("w") as f:
        f.writelines(patch_content)
      source["patches"][patch_name] = integrity(read(patch))

    json_dump(p.joinpath("source.json"), source, sort_keys=False)

    # Create presubmit.yml file
    presubmit_yml = p.joinpath("presubmit.yml")
    if module.presubmit_yml:
      shutil.copy(module.presubmit_yml, presubmit_yml)
    else:
      PLATFORMS = ["debian10", "ubuntu2004", "macos", "windows"]
      presubmit = {
          "matrix": {
              "platform": PLATFORMS.copy(),
          },
          "tasks": {
              "verify_targets": {
                  "name": "Verify build targets",
                  "platform": "${{ platform }}",
                  "build_targets": module.build_targets.copy()
              }
          }
      }

      if module.test_module_path:
        task = {
            "name": "Run test module",
            "platform": "${{ platform }}",
        }
        if module.test_module_build_targets:
          task["build_targets"] = module.test_module_build_targets.copy()
        if module.test_module_test_targets:
          task["test_targets"] = module.test_module_test_targets.copy()
        presubmit["bcr_test_module"] = {
            "module_path": module.test_module_path,
            "matrix": {
                "platform": PLATFORMS.copy(),
            },
            "tasks": {
                "run_test_module": task
            }
        }

      with presubmit_yml.open("w") as f:
        yaml.dump(presubmit, f, sort_keys=False)

    # Add new version to metadata.json
    metadata_path = self.root.joinpath("modules", module.name,
                                       "metadata.json")
    metadata = json.load(metadata_path.open())
    metadata["versions"].append(module.version)
    metadata["versions"] = list(set(metadata["versions"]))
    metadata["versions"].sort(key=Version)
    json_dump(metadata_path, metadata)

  def delete(self, module_name, version):
    """Delete an existing module version."""
    p = self.root.joinpath("modules", module_name)
    shutil.rmtree(p.joinpath(version))
    metadata_path = p.joinpath("metadata.json")
    metadata = json.load(metadata_path.open())
    if version in metadata["versions"]:
      metadata["versions"].remove(version)
    json_dump(metadata_path, metadata)
