#!/usr/bin/env python3
#
# Copyright 2025 The Bazel Authors. All rights reserved.
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

import pathlib
import re
from typing import Optional

from fastmcp import FastMCP

from registry import RegistryClient

ROOT = pathlib.Path(__file__).resolve().parents[1]
client = RegistryClient(ROOT)

mcp = FastMCP("Bazel Central Registry MCP")


@mcp.tool
def list_modules() -> list[str]:
    """Return all module names available in the registry."""
    return client.get_all_modules()


@mcp.tool
def search_modules(pattern: str) -> list[str]:
    """Return module names matching the given regular expression pattern."""
    regex = re.compile(pattern)
    return [m for m in client.get_all_modules() if regex.search(m)]


@mcp.tool
def list_versions(module: str, include_yanked: bool = False) -> list[str]:
    """Return available versions for a module."""
    return [v for _, v in client.get_module_versions(module, include_yanked)]


@mcp.tool
def get_metadata(module: str) -> dict:
    """Return metadata.json information for a module."""
    return client.get_metadata(module)


@mcp.tool
def get_source(module: str, version: str) -> dict:
    """Return source.json for the given module version."""
    return client.get_source(module, version)


@mcp.tool
def get_patch_file(module: str, version: str, patch_name: str) -> Optional[str]:
    """Return the content of a specific patch file if present."""
    path = client.get_patch_file_path(module, version, patch_name)
    return path.read_text() if path.exists() else None


@mcp.tool
def get_module_bazel(module: str, version: str) -> str:
    """Return the contents of MODULE.bazel for a module version."""
    path = client.get_module_dot_bazel_path(module, version)
    return path.read_text()


# This function uses the 'Optional' type hint
@mcp.tool
def get_presubmit_yaml(module: str, version: str) -> Optional[str]:
    """Return presubmit.yml content if present."""
    path = client.get_presubmit_yml_path(module, version)
    return path.read_text() if path.exists() else None


# This function also uses the 'Optional' type hint
@mcp.tool
def get_attestations(module: str, version: str) -> Optional[dict]:
    """Return attestations.json content if present."""
    return client.get_attestations(module, version)


@mcp.tool
def get_registry_info() -> dict:
    """Return the bazel_registry.json data for this registry."""
    path = ROOT / "bazel_registry.json"
    if not path.exists():
        return {}
    import json

    return json.loads(path.read_text())


if __name__ == "__main__":
    mcp.run()
