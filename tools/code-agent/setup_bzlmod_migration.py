#!/usr/bin/env python3
# Copyright 2024 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import stat
import subprocess

AGENTS_MD_TEMPLATE = """
**Role**: You are a **Bazel Expert** specializing in **Bzlmod**. Your task is to systematically migrate a complex repository from the legacy `WORKSPACE` to the new Bzlmod system.

**Goal**: Achieve a successful Bzlmod build for the target `{build_target}` with no fallback to `WORKSPACE`. The final state is defined by a successful run of `bazel build --enable_bzlmod --noenable_workspace --nobuild {build_target}`.

---

### Migration Protocol

Follow this iterative, step-by-step protocol to identify and resolve missing external dependencies.

**Initial Check & Diagnosis**
1.  **Initial Attempt**: Run `bazel build --enable_bzlmod --noenable_workspace --nobuild {build_target}`.
2.  **Identify Failure**: If the build fails, carefully analyze the error message. The primary objective is to identify a single, specific missing repository (e.g., `No repository visible as '@foo'`).
3.  **Legacy Lookup**: Upon identifying a missing repository (`@foo`), run `./check_repo.sh foo` and provide the output, which shows the repository's definition in the legacy `WORKSPACE` environment.

---

### Dependency Resolution Strategy

After reviewing the legacy definition, you must decide the best Bzlmod approach. **Present your full, proposed solution to the user and request confirmation before making any changes.**

**Decision Point (Step 4)**: Check if the dependency is available in BCR and choose and implement one of the following methods:

#### A. Standard Bazel Module
* **When to use**: For dependencies available on the **Bazel Central Registry (BCR)**.
* **Action**: Use the BCR (or the MCP server) to find the correct module name and version.
* **Output**: State the required `bazel_dep` entry to be added to `MODULE.bazel`.

#### B. Module Extension
* **When to use**: For complex, macro-defined, or non-BCR dependencies that require custom logic (e.g., using `http_archive` inside a Starlark macro).
* **Sub-Steps**:
    * **Source Analysis**: Based on the legacy lookup, analyze the contents of `WORKSPACE` and any involved `.bzl` files to understand the repository's definition macro.
    * **Grouping**: If the macro defines multiple external repositories, group them into a single, cohesive module extension.
    * **File Location**: Each module extension **must** be defined in its own `.bzl` file under the path `third_party/extensions/`.
    * **Output**: Provide the complete content for the new extension file and the necessary `use_extension` block for `MODULE.bazel`.

---

### Iteration & Constraints

5.  **Re-Verify**: After applying the changes to `MODULE.bazel`, re-run the check: `bazel build --enable_bzlmod --noenable_workspace --nobuild {build_target}`.
6.  **Repeat**: If the build fails, repeat the process from the **Identify Failure** step (2) for the next missing dependency.
7.  **Final Success**: Stop when the build check succeeds.

**!! CRITICAL CONSTRAINT !!**: **DO NOT** modify any existing files other than **`MODULE.bazel`** (and the creation of new files under `third_party/extensions/` for module extensions). **Adhere strictly to this constraint.**
"""

CHECK_REPO_SH_TEMPLATE = """
#!/bin/bash

set -e

cd {legacy_workspace_path}
bazel query --output=build //external:$1
"""


def main():
    class Colors:
        is_tty = os.isatty(1)
        HEADER = "\033[95m" if is_tty else ""
        OKBLUE = "\033[94m" if is_tty else ""
        OKGREEN = "\033[92m" if is_tty else ""
        WARNING = "\033[93m" if is_tty else ""
        FAIL = "\033[91m" if is_tty else ""
        ENDC = "\033[0m" if is_tty else ""
        BOLD = "\033[1m" if is_tty else ""
        UNDERLINE = "\033[4m" if is_tty else ""

    print(f"{Colors.BOLD}Setup helper files for a Coding Agent to migrate your project to" f" Bzlmod.{Colors.ENDC}")
    print("\nThis script will generate two files in your current directory:")
    print(f"1. An agent instruction file (e.g., {Colors.OKBLUE}GEMINI.md{Colors.ENDC}) to" " guide the AI assistant.")
    print("2. A" f" {Colors.OKBLUE}`check_repo.sh`{Colors.ENDC} script to query your legacy" " WORKSPACE setup.")
    print(
        f"\n{Colors.WARNING}IMPORTANT:{Colors.ENDC} Please make sure you are running"
        " this script from the root of your project."
    )

    # Create a temporary directory for the legacy workspace
    legacy_workspace_path = os.path.join(
        os.path.expanduser("~"),
        "bzlmod_migration_legacy_workspace",
        os.path.basename(os.getcwd()),
    )
    print(
        "\nThis script will now create a temporary, shallow clone of your project to"
        " serve as the legacy workspace at"
        f" {Colors.OKBLUE}{legacy_workspace_path}{Colors.ENDC}."
    )
    input(f"{Colors.OKGREEN}Press Enter to continue or Ctrl+C to exit...{Colors.ENDC}")
    print("Setting up a temporary legacy workspace by cloning the current project...")
    try:
        subprocess.run(
            ["git", "clone", "--depth", "1", ".", legacy_workspace_path],
            check=True,
            capture_output=True,
            text=True,
        )
        print(f"{Colors.OKGREEN}Legacy workspace is ready at:" f" {legacy_workspace_path}{Colors.ENDC}")
    except subprocess.CalledProcessError as e:
        print(f"{Colors.FAIL}Error creating the legacy workspace clone.{Colors.ENDC}")
        print(f"Stderr: {e.stderr}")
        return  # Exit if clone fails

    build_target = input(
        "\nPlease provide a build target to verify the migration. The goal is to make"
        f" `{Colors.BOLD}bazel build --enable_bzlmod --noenable_workspace --nobuild"
        f" <build target>{Colors.ENDC}` successful."
        "\nMake sure your build target works in the legacy workspace with"
        f" `{Colors.BOLD}bazel build --enable_workspace --noenable_bzlmod --nobuild"
        f" <build target>{Colors.ENDC}`."
        f"\n{Colors.OKGREEN}Enter the target to migrate: {Colors.ENDC}"
    )
    while not build_target:
        print(f"{Colors.WARNING}This field is required.{Colors.ENDC}")
        build_target = input(f"{Colors.OKGREEN}Enter the target to migrate: {Colors.ENDC}")

    agent_file = (
        input("Enter the name of the agent file to generate (default:" f" '{Colors.OKBLUE}GEMINI.md{Colors.ENDC}'): ")
        or "GEMINI.md"
    )

    output_dir = "."
    os.makedirs(output_dir, exist_ok=True)

    # Generate agent file
    agents_md_content = AGENTS_MD_TEMPLATE.format(build_target=build_target)
    agents_md_path = os.path.join(output_dir, agent_file)
    with open(agents_md_path, "w") as f:
        f.write(agents_md_content)
    print(f"{Colors.OKGREEN}Generated {agents_md_path}{Colors.ENDC}")

    # Generate check_repo.sh
    check_repo_sh_content = CHECK_REPO_SH_TEMPLATE.format(legacy_workspace_path=legacy_workspace_path)
    check_repo_sh_path = os.path.join(output_dir, "check_repo.sh")
    with open(check_repo_sh_path, "w") as f:
        f.write(check_repo_sh_content)

    # Make check_repo.sh executable
    st = os.stat(check_repo_sh_path)
    os.chmod(check_repo_sh_path, st.st_mode | stat.S_IEXEC)
    print(f"{Colors.OKGREEN}Generated {check_repo_sh_path} and made it" f" executable.{Colors.ENDC}\n")
    print(
        f"{Colors.BOLD}Make sure `./check_repo.sh bazel_skylib` works, you should see"
        " the repository definition of @bazel_skylib, or any other repo you"
        f" choose.{Colors.ENDC}"
    )


if __name__ == "__main__":
    main()
