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
"""Tool script for select module versions from BCR"""

import argparse
import re
import random

from registry import RegistryClient

def select_modules(registry, selections, random_percentage=None):
    """
    Select module versions matching the given patterns and optionally apply a random sample percentage.
    """
    if not selections:
        return []

    selected_modules = []

    for selection in selections:
        if '@' not in selection:
            raise ValueError(f"Invalid selection pattern (missing '@'): {selection}")

        module_pattern, version = selection.split('@', 1)

        if not module_pattern or not version:
            raise ValueError(f"Invalid selection pattern: {selection}")

        regex_pattern = '^' + module_pattern.replace('.', '\\.').replace('*', '.*') + '$'
        module_regex = re.compile(regex_pattern)

        matching_modules = [
            module for module in registry.get_all_modules()
            if module_regex.match(module)
        ]

        for module in matching_modules:
            module_versions = [m[1] for m in registry.get_module_versions(module)] # This should be sorted already
            if version == 'latest':
                latest_version = module_versions[-1]
                selected_modules.append(f"{module}@{latest_version}")
            else:
                if len(matching_modules) > 2:
                    # Pattern like rules_*@1.2 should not be allowed.
                    raise ValueError(f"Cannot specify a specific version for multiple matching modules: {module_pattern}")
                if version in module_versions:
                    selected_modules.append(f"{module}@{version}")
                else:
                    raise ValueError(f"Version {version} of module {module} not found.")

    if random_percentage is not None:
        try:
            percentage = int(random_percentage)
            if not (0 < percentage <= 100):
                raise ValueError
        except ValueError:
            raise ValueError("Random percentage must be an integer between 1 and 100.")

        total_modules = len(selected_modules)
        num_to_select = max(1, (percentage * total_modules) // 100)
        selected_modules = random.sample(selected_modules, num_to_select)

    if not selected_modules:
        raise ValueError("No matching modules found.")

    return selected_modules

def main():
    parser = argparse.ArgumentParser(description='Select module versions matching given patterns.')
    parser.add_argument("--registry", type=str, default=".", help="Specify the root path of the registry (default: the current working directory).")
    parser.add_argument('--select', action="append", required=True, help='Module selection patterns, supporting wildcards.')
    parser.add_argument('--random-percentage', type=int, metavar='PERCENTAGE',
                        help='Percentage of modules to randomly select from the modules matching any of the patterns. Must be an integer between 1 and 100.')

    args = parser.parse_args()

    registry = RegistryClient(args.registry)
    module_selections = args.select
    random_percentage = args.random_percentage

    selected_module_versions = select_modules(registry, module_selections, random_percentage)
    for module_version in selected_module_versions:
        print(module_version)

if __name__ == "__main__":
    main()
