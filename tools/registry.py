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

from colorama import Fore, Style
from pathlib import Path

import base64
import difflib
import hashlib
import json
import shutil
import urllib.request
import yaml


def log(msg):
    print(f"{Fore.GREEN}INFO: {Style.RESET_ALL}{msg}")


def download(url):
    response = urllib.request.urlopen(url)
    return response.read()


def read(path):
    f = open(path, "rb")
    return f.read()


def integrity(data):
    hash_value = hashlib.sha256(data)
    return "sha256-" + base64.b64encode(hash_value.digest()).decode()


class Module(object):

    def __init__(self, name=None, version=None, compatibility_level=1):
        self.name = name
        self.version = version
        self.compatibility_level = compatibility_level
        self.module_dot_bazel = None
        self.deps = []
        self.patches = []
        self.patch_strip = 0
        self.build_file = None
        self.presubmit_yml = None
        self.build_targets = []
        self.test_targets = []

    def add_dep(self, module_name, version):
        self.deps.append((module_name, version))
        return self

    def set_module_dot_bazel(self, module_dot_bazel):
        self.module_dot_bazel = module_dot_bazel

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

    def add_test_targets(self, target):
        if not target.startswith("@" + self.name):
            target = "@" + self.name + target
        self.test_targets.append(target)
        return self

    def dump(self, file):
        with open(file, "w") as f:
            json.dump(self.__dict__, f, indent=4, sort_keys=True)

    def from_json(self, file):
        with open(file) as f:
            self.__dict__ = json.load(f)


class RegistryModifyException(Exception):
    """
    Raised whenever something goes wrong with modifying the registry.
    """
    pass


class RegistryClient(object):
    _MODULE_BAZEL = """
module(
    name = "{0}",
    version = "{1}",
    compatibility_level = {2},
)
""".strip()

    def __init__(self, root):
        self.root = Path(root)

    def contains(self, module_name, version=None):
        """
        Check if the registry contains a module or a specific version of a
        module by verifying if the directory exists.
        """
        p = self.root.joinpath("modules", module_name)
        if version:
            p = p.joinpath(version)
        return p.is_dir()

    def init_module(self, module_name, maintainers, homepage):
        """
        Initialize a module, create the directory and metadata.json file.

        Parameters
        ----------
        module_name : str
            The module name
        maintainers : list of maps of string -> string
            The maintainer information, eg
             [{"name": "John Cater", "email": "jcater@google.com"},
              {"name": "Yun Peng", "github": "meteorcloudy"}]
        homepage : str
            A URL to the project's homepage

        """
        p = self.root.joinpath("modules", module_name)
        p.mkdir(parents=True, exist_ok=True)

        # Create metadata.json file
        metadata = {
            "maintainers": maintainers,
            "homepage": homepage,
            "versions": [],
            "yanked_versions": {},
        }
        with p.joinpath("metadata.json").open("w") as f:
            json.dump(metadata, f, indent=4, sort_keys=True)

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
                log("Overridding module '%s' at version '%s'..." % (module.name, module.version))
                self.delete(module.name, module.version)
            else:
                raise RegistryModifyException(
                    f"Version {module.version} for module {module.name} already exists.")

        p = self.root.joinpath("modules", module.name, module.version)
        p.mkdir()

        # Create MODULE.bazel
        module_dot_bazel = p.joinpath("MODULE.bazel")
        if module.module_dot_bazel:
            shutil.copy(module.module_dot_bazel, module_dot_bazel)
        else:
            deps = "\n".join(
                f"bazel_dep(name = \"{name}\", version = \"{version}\")"
                for name, version in module.deps)
            with module_dot_bazel.open("w") as f:
                f.write(self._MODULE_BAZEL.format(
                    module.name, module.version,
                    module.compatibility_level) + deps)

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
                patch = Path(s)
                source["patches"][patch.name] = integrity(read(patch))
                shutil.copy(patch, patch_dir)

        # Turn additional build file into a patch
        if module.build_file:
            build_file_content = Path(module.build_file).open().readlines()
            build_file = "a/" * module.patch_strip + "BUILD.bazel"
            patch_content = difflib.unified_diff([], build_file_content, "/dev/null", build_file)
            patch_name = "add_build_file.patch"
            patch = patch_dir.joinpath(patch_name)
            with patch.open("w") as f:
                f.writelines(patch_content)
            source["patches"][patch_name] = integrity(read(patch))

        with p.joinpath("source.json").open("w") as f:
            json.dump(source, f, indent=4, sort_keys=True)

        # Create presubmit.yml file
        presubmit_yml = p.joinpath("presubmit.yml")
        if module.presubmit_yml:
            shutil.copy(module.presubmit_yml, presubmit_yml)
        else:
            platforms = {
                "linux": {},
                "macos": {},
                "windows": {},
            }
            for key in platforms:
                if module.build_targets:
                    platforms[key]["build_targets"] = module.build_targets.copy()
                if module.test_targets:
                    platforms[key]["test_targets"] = module.test_targets.copy()
            with presubmit_yml.open("w") as f:
                yaml.dump({"platforms": platforms}, f)

        # Add new version to metadata.json
        metadata_path = self.root.joinpath("modules", module.name,
                                           "metadata.json")
        metadata = json.load(metadata_path.open())
        metadata["versions"].append(module.version)
        metadata["versions"] = list(set(metadata["versions"]))
        metadata["versions"].sort()
        with metadata_path.open("w") as f:
            json.dump(metadata, f, indent=4, sort_keys=True)

    def delete(self, module_name, version):
        """
        Delete an existing module version

        """
        p = self.root.joinpath("modules", module_name)
        shutil.rmtree(p.joinpath(version))
        metadata_path = p.joinpath("metadata.json")
        metadata = json.load(metadata_path.open())
        if version in metadata["versions"]:
            metadata["versions"].remove(version)
        with metadata_path.open("w") as f:
            json.dump(metadata, f, indent=4, sort_keys=True)
