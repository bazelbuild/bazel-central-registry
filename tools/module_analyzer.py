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
import subprocess
import networkx as nx

from registry import RegistryClient
from module_selector import select_modules

def get_direct_dependencies(module_name, version, registry_dir):
    deps = subprocess.check_output(
        ["buildozer", "print name", f"//modules/{module_name}/{version}/MODULE.bazel:%bazel_dep"],
        cwd=registry_dir,
    ).decode("utf-8").split()

    dev_deps_stat = subprocess.check_output(
        ["buildozer", "print dev_dependency", f"//modules/{module_name}/{version}/MODULE.bazel:%bazel_dep"],
        cwd=registry_dir,
        stderr=subprocess.DEVNULL  # Suppress stderr
    ).decode("utf-8").split()

    direct_deps = []
    for i, dep in enumerate(deps):
      if dev_deps_stat[i] != "True":
          direct_deps.append(dep)

    return deps

def main():
    parser = argparse.ArgumentParser(description="Select module versions matching given patterns.")
    parser.add_argument(
        "--registry",
        type=str,
        default=".",
        help="Specify the root path of the registry (default: the current working directory).",
    )

    args = parser.parse_args()

    registry = RegistryClient(args.registry)

    # Select all modules at their latest versions
    modules = select_modules(registry, ["*@latest"])

    G = nx.DiGraph()
    for module in modules:
        module_name, version = module.split("@")
        for dep in get_direct_dependencies(module_name, version, args.registry):
            G.add_edge(module_name, dep)

    pagerank = nx.pagerank(G)

    sorted_modules = sorted(pagerank.items(), key=lambda x: x[1], reverse=True)

    N = 50
    print(f"Top {N} Modules by PageRank:")
    for module, score in sorted_modules[:N]:
        print(f"{module}: {score:.6f}")


if __name__ == "__main__":
    main()
