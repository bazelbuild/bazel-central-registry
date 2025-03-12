#!/usr/bin/env python3
#
# Copyright 2024 The Bazel Authors. All rights reserved.
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
"""Tool script for analyzing BCR modules"""

import argparse
import os
import subprocess
import networkx as nx

from runfiles import Runfiles
from registry import RegistryClient
from module_selector import select_modules


def get_buildozer_path():
    if "RUNFILES_MANIFEST_FILE" in os.environ:
        # The ".exe" suffix is *not* a typo. It is present on all platforms to support
        path = Runfiles.Create().Rlocation("buildozer_binary/buildozer.exe")
        if path:
            return path
    # Fallback to use buildozer in PATH.
    return "buildozer"


def get_direct_dependencies(module_name, version, registry_dir, buildozer, exclude_dev_deps):
    deps = (
        subprocess.check_output(
            [buildozer, "print name", f"//modules/{module_name}/{version}/MODULE.bazel:%bazel_dep"],
            cwd=registry_dir,
        )
        .decode("utf-8")
        .split()
    )

    if not exclude_dev_deps:
        return deps

    dev_deps_stat = (
        subprocess.check_output(
            [buildozer, "print dev_dependency", f"//modules/{module_name}/{version}/MODULE.bazel:%bazel_dep"],
            cwd=registry_dir,
            stderr=subprocess.DEVNULL,  # Suppress stderr
        )
        .decode("utf-8")
        .split()
    )

    direct_deps = []
    for i, dep in enumerate(deps):
        if dev_deps_stat[i] != "True":
            direct_deps.append(dep)

    return direct_deps


def main():
    parser = argparse.ArgumentParser(description="Select module versions matching given patterns.")
    parser.add_argument(
        "--registry",
        type=str,
        default=".",
        help="Specify the root path of the registry (default: the current working directory or the workspace root if running with Bazel).",
    )
    parser.add_argument(
        "--top_n",
        type=int,
        default=50,
        help="Specify the top N important modules to print out (default: 50).",
    )
    parser.add_argument(
        "--exclude-dev-deps",
        action="store_true",
        help="Exclude dev dependencies when constructing the dependency graph (default: False).",
    )
    parser.add_argument(
        "--name-only",
        action="store_true",
        help="Only print the module names without the scores (default: False).",
    )

    args = parser.parse_args()

    # Find buildozer binary
    buildozer = get_buildozer_path()

    registry = RegistryClient(args.registry)

    # Select all modules at their latest versions
    modules = select_modules(registry, ["*@latest"])

    G = nx.DiGraph()
    for module in modules:
        module_name, version = module.split("@")
        for dep in get_direct_dependencies(module_name, version, args.registry, buildozer, args.exclude_dev_deps):
            # It is possible for a MODULE.bazel to contain a bazel_dep with an override that is not in the registry
            if not registry.contains(dep):
                continue
            G.add_edge(module_name, dep)

    pagerank = nx.pagerank(G)

    sorted_modules = sorted(pagerank.items(), key=lambda x: x[1], reverse=True)

    N = min(args.top_n, len(sorted_modules))

    if args.name_only:
        for module, _ in sorted_modules[:N]:
            print(module)
        return

    print(f"Top {N} Modules by PageRank:")
    for module, score in sorted_modules[:N]:
        print(f"{module}: {score:.6f}")


if __name__ == "__main__":
    if "BUILD_WORKSPACE_DIRECTORY" in os.environ:
        os.chdir(os.environ["BUILD_WORKSPACE_DIRECTORY"])
    main()
