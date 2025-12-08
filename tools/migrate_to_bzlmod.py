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

import argparse
import importlib.util
import json
import locale
import pathlib
import re
import subprocess
import sys
import tempfile
import os

from urllib.parse import urlparse
from registry import RegistryClient

# The registry client points to the bazel central registry repo
REGISTRY_CLIENT = RegistryClient(pathlib.Path(__file__).resolve().parent.joinpath("../"))

USE_REPO_RULE_IDENTIFIER = "# -- use_repo_rule statements -- #"
LOAD_IDENTIFIER = "# -- load statements -- #"
REPO_IDENTIFIER = "# -- repo definitions -- #"
BAZEL_DEP_IDENTIFIER = "# -- bazel_dep definitions -- #"


def abort_migration():
    info("Abort migration...")
    exit(2)


def assertExitCode(exit_code, expected_exit_code, error_message, stderr):
    if exit_code != expected_exit_code:
        error(f"Command exited with {exit_code}, expected {expected_exit_code}:")
        eprint(error_message)
        eprint(stderr)
        abort_migration()


def eprint(*args, **kwargs):
    """
    Print to stderr and flush (just in case).
    """
    print(*args, flush=True, file=sys.stderr, **kwargs)


BOLD = "\033[1m"
GREEN = "\x1b[32m\033[1m"
YELLOW = "\x1b[33m\033[1m"
RED = "\x1b[31m\033[1m"
RESET = "\033[0m"


def info(msg):
    eprint(msg)


def resolved(msg):
    eprint(f"{GREEN}RESOLVED: {RESET}{msg}")


def important(msg):
    eprint(f"{YELLOW}IMPORTANT: {RESET}{msg}")


def action(msg):
    eprint(f"{RED}ACTION NEEDED: {RESET}{msg}")


def warning(msg):
    eprint(f"{YELLOW}WARNING: {RESET}{msg}")


def error(msg):
    eprint(f"{RED}ERROR: {RESET}{msg}")


def ask_input(msg):
    return input(f"{YELLOW}ACTION: {RESET}{msg}")


def yes_or_no(question, default):
    if not yes_or_no.enable:
        return default

    if default:
        question += " [Y/n]: "
    else:
        question += " [y/N]: "

    var = None
    while var is None:
        user_input = ask_input(question).strip().lower()
        if user_input == "y":
            var = True
        elif user_input == "n":
            var = False
        elif not user_input:
            var = default
        else:
            eprint(f"Invalid selection: {user_input}")
    return var


def scratch_file(file_path, lines=None, mode="w"):
    """Write lines to a file."""
    abspath = pathlib.Path(file_path)
    with open(abspath, mode) as f:
        if lines:
            for l in lines:
                f.write(l)
                f.write("\n")
    return abspath


def append_to_file(filename, content):
    """
    Creates a file with the given filename and content.

    Args:
        filename (str): The name of the file to create.
        content (str): The content to write to the file.
    """
    try:
        with open(filename, "a") as f:
            f.write(content)
    except OSError as e:
        error(f"Error creating file '{filename}': {e}")


def append_migration_info(content):
    """Adds content to the "migration_info" file in order to help users with details about the migration."""
    append_to_file("migration_info.md", content + "\n")


def execute_command(args, to_print=False, cwd=None, env=None, shell=False, executable=None):
    if to_print:
        info("Executing command: " + " ".join(args))
    with tempfile.TemporaryFile() as stdout:
        with tempfile.TemporaryFile() as stderr:
            proc = subprocess.Popen(
                args,
                executable=executable,
                stdout=stdout,
                stderr=stderr,
                cwd=cwd,
                env=env,
                shell=shell,
            )
            exit_code = proc.wait()

            stdout.seek(0)
            stdout_result = stdout.read().decode(locale.getpreferredencoding())
            stderr.seek(0)
            stderr_result = stderr.read().decode(locale.getpreferredencoding())
            return exit_code, stdout_result, stderr_result


def print_repo_definition(repo_def, dep):
    repo_def_str = "\n".join(repo_def)
    append_migration_info(f"""
<details>
<summary>Click here to see where and how the repo was declared in the WORKSPACE file</summary>

#### Location
```python
{dep["definition_information"]}
```

#### Definition
```python
{repo_def_str}
```
**Tip**: URLs usually show which version was used.
</details>
""")
    append_migration_info("___")


def repo_definition(dep):
    """Print the repository info to migration_info and return the repository definition."""
    # Parse the repository rule class (rule name, and the label for the bzl file where the rule is defined.)
    rule_class = dep["original_rule_class"]
    is_macro = False
    if rule_class.find("%") != -1:
        # Starlark rule
        file_label, rule_name = rule_class.split("%")
        # If the original macro is not publicly visible, we trace back to fine a visible one.
        if rule_name.startswith("_"):
            is_macro = True
            def_info = dep["definition_information"].split("\n")
            def_info.reverse()
            for line in def_info:
                s = re.match(r"^  (.+):[0-9]+:[0-9]+: in ([^\_<].+)$", line)
                if s:
                    new_file_name, new_rule_name = s.groups()
                    if new_file_name.endswith(file_label.split("//")[1].replace(":", "/")):
                        rule_name = new_rule_name
                    else:
                        warning(
                            f"A visible macro for {rule_name} is defined in a different bzl file `{new_file_name}` "
                            f"other than `{file_label}`, "
                            f"you have to find out the correct label for `{new_file_name}` manually."
                        )
                    break
    else:
        # Native rule
        file_label = None
        rule_name = rule_class

    # Generate the repository definition lines.
    repo_def = []
    if file_label:
        repo_def.append(f'load("{file_label}", "{rule_name}")')
    repo_def.append(f"{rule_name}(")
    for key, value in dep["original_attributes"].items():
        if not key.startswith("generator_"):
            value_str = json.dumps(value, indent=4)
            # Fix indentation
            if value_str.endswith("}") or value_str.endswith("]"):
                value_str = value_str[:-1] + "  " + value_str[-1]
            # Fix boolean format
            if value_str == "false" or value_str == "true":
                value_str = value_str[0].upper() + value_str[1:]
            repo_def.append(f"  {key} = {value_str},")
    repo_def.append(")")

    if file_label and file_label.startswith("@@"):
        file_label = file_label[1:]

    return repo_def, file_label, rule_name, is_macro


def detect_unavailable_repo_error(stderr):
    PATTERNS = [
        re.compile(r"unknown repo '([A-Za-z0-9_-]+)' requested from"),
        re.compile(r"The repository '@([A-Za-z0-9_-]+)' could not be resolved"),
        re.compile(r"No repository visible as '@([A-Za-z0-9_-]+)' from main repository"),
        re.compile(r"This could either mean you have to add the '@([A-Za-z0-9_-]+)' repository"),
        re.compile(r"no repo visible as '@([A-Za-z0-9_-]+)' here"),
    ]

    for line in stderr.split("\n"):
        for p in PATTERNS:
            m = p.search(line)
            if m:
                return m.groups()[0]

    return None


def write_at_given_place(filename, new_content, identifier):
    """Write content to a file at a position marked by the identifier."""
    file_content = ""
    with open(filename, "r") as f:
        file_content = f.read()
        file_content = file_content.replace(
            identifier,
            new_content + "\n" + identifier,
            1,
        )
    with open(filename, "w") as f:
        f.write(file_content)


def add_repo_with_use_repo_rule(repo, repo_def, file_label, rule_name):
    """Introduce a repository with use_repo_rule in the MODULE.bazel file."""
    use_repo_rule = f'{rule_name} = use_repo_rule("{file_label}", "{rule_name}")'

    # Check if the use_repo_rule is already in the MODULE.bazel file
    module_bazel_content = open("MODULE.bazel", "r").read()
    if use_repo_rule not in module_bazel_content:
        write_at_given_place("MODULE.bazel", use_repo_rule, USE_REPO_RULE_IDENTIFIER)

    # Add the repo definition to the MODULE.bazel file
    write_at_given_place(
        "MODULE.bazel",
        "\n".join([""] + repo_def[1:]),
        REPO_IDENTIFIER,
    )


def add_repo_to_module_extension(repo, repo_def, file_label, rule_name):
    """Introduce a repository via a module extension."""
    # If the repo was not defined in @bazel_tools,
    # we need to create a separate module extension for it to avoid cycle.
    if rule_name.startswith("_"):
        rule_name = rule_name[1:]
    need_separate_module_extension = not file_label.startswith("@bazel_tools")
    ext_name = f"extension_for_{rule_name}".replace("-", "_") if need_separate_module_extension else "non_module_deps"
    ext_bzl_name = ext_name + ".bzl"

    # Generate the initial bzl file for the module extension
    if not pathlib.Path(ext_bzl_name).is_file():
        scratch_file(
            ext_bzl_name,
            [
                LOAD_IDENTIFIER,
                "",
                f"def _{ext_name}_impl(ctx):",
                REPO_IDENTIFIER,
                "",
                f"{ext_name} = module_extension(implementation = _{ext_name}_impl)",
            ],
        )

    # Add repo definition to the module extension's bzl file
    imported_rule_statement = f'"{rule_name}"'
    load_statement = f'load("{file_label}", {imported_rule_statement})'
    bzl_content = open(ext_bzl_name, "r").read()
    if imported_rule_statement not in bzl_content:
        write_at_given_place(ext_bzl_name, load_statement, LOAD_IDENTIFIER)
    repo_def_str = "\n".join(["  " + line.replace("\n", "\n  ") for line in repo_def[1:]])
    write_at_given_place(
        ext_bzl_name,
        repo_def_str,
        REPO_IDENTIFIER,
    )

    # Add use_repo statement in the MODULE.bazel file
    use_ext = f'{ext_name} = use_extension("//:{ext_name}.bzl", "{ext_name}")'
    module_bazel_content = open("MODULE.bazel", "r").read()
    ext_identifier = f"# End of extension `{ext_name}`"
    append_migration_info("```")
    if use_ext not in module_bazel_content:
        scratch_file("MODULE.bazel", ["", use_ext, ext_identifier], mode="a")
        append_migration_info(use_ext + "\n")
    use_repo_msg = f'use_repo({ext_name}, "{repo}")'
    write_at_given_place("MODULE.bazel", use_repo_msg, ext_identifier)
    append_migration_info(use_repo_msg)
    append_migration_info("```")


def url_match_source_repo(source_url, module_name):
    source_repositories = REGISTRY_CLIENT.get_metadata(module_name).get("repository", [])
    matched = False
    parts = urlparse(source_url)
    for source_repository in source_repositories:
        if matched:
            break
        repo_type, repo_path = source_repository.split(":")
        # Include repos which were moved to bazel-contrib:
        # https://github.com/orgs/bazelbuild/discussions/2#discussioncomment-10671359.
        repo_path = repo_path.replace("bazel-contrib/", "bazelbuild/")
        if repo_type == "github":
            matched = (
                parts.scheme == "https"
                and parts.netloc == "github.com"
                and (
                    os.path.abspath(parts.path).startswith(f"/{repo_path}/")
                    or os.path.abspath(parts.path).startswith(f"/{repo_path}.git")
                )
            )
        elif repo_type == "https":
            repo = urlparse(source_repository)
            matched = (
                parts.scheme == repo.scheme
                and parts.netloc == repo.netloc
                and os.path.abspath(parts.path).startswith(f"{repo.path}/")
            )
    return matched


def exists_in_file(filename, content):
    with open(filename, "r") as f:
        return content in f.read()


def add_go_extension(repo, origin_attrs, resolved_deps, workspace_name):
    # Introduce `bazel_gazelle` only once.
    if not exists_in_file("MODULE.bazel", 'bazel_dep(name = "gazelle'):
        address_unavailable_repo("bazel_gazelle", resolved_deps, workspace_name)

    # Introduce `io_bazel_rules_go` only once.
    if not exists_in_file("MODULE.bazel", 'bazel_dep(name = "rules_go'):
        address_unavailable_repo("io_bazel_rules_go", resolved_deps, workspace_name)

    # Add go_deps
    if not exists_in_file("MODULE.bazel", 'use_extension("@bazel_gazelle//:extensions.bzl", "go_deps'):
        go_deps = """
go_deps = use_extension("@bazel_gazelle//:extensions.bzl", "go_deps")
# -- End of go extension -- #
"""
        write_at_given_place("MODULE.bazel", go_deps, REPO_IDENTIFIER)

    # Add go_sdk
    if not exists_in_file("MODULE.bazel", '@io_bazel_rules_go//go:extensions.bzl", "go_sdk'):
        go_sdk = """go_sdk = use_extension("@io_bazel_rules_go//go:extensions.bzl", "go_sdk")
"""
        write_at_given_place("MODULE.bazel", go_sdk, "# -- End of go extension -- #")

    resolved("`" + repo + "` has been introduced as go extension.")
    append_migration_info("## Migration of `" + repo + "`:")

    if os.path.exists("go.mod") and os.path.exists("go.sum"):
        if exists_in_file("MODULE.bazel", origin_attrs["name"]):
            append_migration_info("It has already been introduced as a go module with the help of `go.mod`.\n")

        if not exists_in_file("MODULE.bazel", 'go_deps.from_file(go_mod = "//:go.mod")'):
            from_file = """go_deps.from_file(go_mod = "//:go.mod")
go_sdk.from_file(go_mod = "//:go.mod")
"""
            write_at_given_place("MODULE.bazel", from_file, "# -- End of go extension -- #")
            exit_code, stdout, _ = execute_command(["bazel", "mod", "tidy", "--enable_bzlmod"])
            assertExitCode(exit_code, 0, "Failed to run `bazel mod tidy`", stdout)
            append_migration_info("It has been introduced as a go module with the help of `go.mod`:\n")
            append_migration_info("```\n" + from_file + "```")
    else:
        go_module = ["go_deps.module("]
        if "importpath" in origin_attrs:
            go_module.append('    path = "' + origin_attrs["importpath"] + '",')
        if "sum" in origin_attrs:
            go_module.append('    sum = "' + origin_attrs["sum"] + '",')
        if "version" in origin_attrs:
            go_module.append('    version = "' + origin_attrs["version"] + '",')
        elif "tag" in origin_attrs:
            go_module.append('    version = "' + origin_attrs["tag"] + '",')
        go_module.append(")\n")

        write_at_given_place(
            "MODULE.bazel",
            'use_repo(go_deps, "' + origin_attrs["name"] + '")',
            "# -- End of go extension -- #",
        )
        write_at_given_place("MODULE.bazel", "\n".join(go_module), "use_repo(go_deps, ")
        append_migration_info("It has been introduced as a go module:\n")
        append_migration_info("```\n" + "\n".join(go_module) + "```")

    # Add gazelle_override if needed.
    gazelle_override_attrs = []
    if "build_file_proto_mode" in origin_attrs:
        gazelle_override_attrs.append('"gazelle:proto ' + origin_attrs["build_file_proto_mode"] + '",')
    if "build_naming_convention" in origin_attrs:
        gazelle_override_attrs.append('"gazelle:go_naming_convention ' + origin_attrs["build_naming_convention"] + '",')
    if gazelle_override_attrs:
        directives = "\n         ".join(gazelle_override_attrs)
        gazelle_override = f"""go_deps.gazelle_override(
    path = "{origin_attrs["importpath"]}",
    directives = [
        {directives}
    ],
)
"""
        write_at_given_place("MODULE.bazel", gazelle_override, "# -- End of go extension -- #")
        append_migration_info("Additionally, `gazelle_override` was used for the initial directives:\n")
        append_migration_info("```\n" + gazelle_override + "```")


def add_testonly_maven_artifact(group, artifact, version, repo):
    test_artifact = f"""maven.artifact(
    testonly = True,
    group = "{group}",
    artifact = "{artifact}",
    version = "{version}"
)
"""
    write_at_given_place(
        "MODULE.bazel",
        test_artifact,
        f"# -- End of maven artifacts for repo `{repo}` ",
    )

    resolved("`" + group + "` has been introduced as maven artifact (testonly).")
    append_migration_info("## Migration of `" + group + "` (" + repo + "):")
    append_migration_info("It has been introduced as a maven artifact (testonly):\n")
    append_migration_info("```\n" + test_artifact + "```")


def add_maven_extension(repo, maven_artifacts, repositories, resolved_deps, workspace_name):
    # Introduce `rules_jvm_external` only once.
    if not exists_in_file("MODULE.bazel", 'bazel_dep(name = "rules_jvm_external'):
        address_unavailable_repo("rules_jvm_external", resolved_deps, workspace_name)

    # Introduce `maven` extension only once.
    if not exists_in_file("MODULE.bazel", 'maven = use_extension("@rules_jvm_external//:extensions.bzl"'):
        maven_extension = """
maven = use_extension("@rules_jvm_external//:extensions.bzl", "maven")
# -- End of maven extensions -- #
"""
        write_at_given_place(
            "MODULE.bazel",
            maven_extension,
            REPO_IDENTIFIER,
        )

    # Introduce repo rule for `repo` only once.
    if not exists_in_file("MODULE.bazel", f'use_repo(maven, "{repo}")'):
        repo_rule = f"""
use_repo(maven, "{repo}")
# -- End of maven artifacts for repo `{repo}` -- #"""
        write_at_given_place(
            "MODULE.bazel",
            repo_rule,
            "# -- End of maven extensions",
        )

    parsed_artifacts = []
    # If the repo is `testonly`, translate it as `maven.artifact`. Otherwise, use `maven.install`.
    for maven_artifact in maven_artifacts:
        parsed_data = json.loads(maven_artifact)
        group = parsed_data["group"]
        artifact = parsed_data["artifact"]
        version = parsed_data["version"]

        if "testonly" in parsed_data and parsed_data["testonly"]:
            add_testonly_maven_artifact(group, artifact, version, repo)
            continue

        parsed_artifact = '"' + group + ":" + artifact + ":" + version + '",'
        parsed_artifacts.append(parsed_artifact)

    parsed_repositories = []
    for repository in repositories:
        parsed_data = json.loads(repository)
        parsed_repositories.append('"' + parsed_data["repo_url"] + '",')

    name = "" if repo == "maven" else '\n\tname = "' + repo + '",'
    parsed_artifacts = "\n\t\t".join(parsed_artifacts)
    parsed_repositories = "\n\t\t".join(parsed_repositories)
    maven_install = f"""maven.install({name}
    artifacts = [
        {parsed_artifacts}
    ],
    repositories = [
        {parsed_repositories}
    ],
)
"""
    write_at_given_place(
        "MODULE.bazel",
        maven_install,
        f"# -- End of maven artifacts for repo `{repo}` ",
    )

    resolved("`" + repo + "` has been introduced as maven extension.")
    append_migration_info("## Migration of `" + repo + "`:")
    append_migration_info("It has been introduced as a maven extension:\n")
    append_migration_info("```\n" + maven_install + "```")


def add_python_extension(repo, origin_attrs, resolved_deps, workspace_name):
    # Introduce `rules_python` only once.
    if not exists_in_file("MODULE.bazel", 'bazel_dep(name = "rules_python"'):
        address_unavailable_repo("rules_python", resolved_deps, workspace_name)

    # Introduce `pip` extension only once.
    if not exists_in_file("MODULE.bazel", 'pip = use_extension("@rules_python//python/extensions:pip.bzl", "pip")'):
        pip_extension = """
pip = use_extension("@rules_python//python/extensions:pip.bzl", "pip")
# -- End of pip extensions -- #
"""
        write_at_given_place(
            "MODULE.bazel",
            pip_extension,
            REPO_IDENTIFIER,
        )

    # Determine python version to use. Check for an existing default or use 3.11.
    python_version = "3.11"
    try:
        with open("MODULE.bazel", "r") as f:
            match = re.search(r'python\.defaults\s*\(\s*python_version\s*=\s*"([^"]+)"', f.read())
    except FileNotFoundError:
        match = None

    if match:
        python_version = match.group(1)
    else:
        important(
            (
                f"{python_version} is used as a default python version.\n"
                "\t\tIf you need a different version, please change it manually and then rerun the migration tool.\n"
                "\t\tIf you're using `python_register_multi_toolchains`, add `python.toolchain` for each python version."
            )
        )

    py_ext = f"""
pip.parse(
    hub_name = "{repo}",
    requirements_lock = "{origin_attrs["requirements_lock"]}",
    python_version = "{python_version}",
)
use_repo(pip, "{repo}")"""
    write_at_given_place(
        "MODULE.bazel",
        py_ext,
        "# -- End of pip extensions -- #",
    )

    py_toolchain = []
    # Introduce `python` extension only once.
    if not exists_in_file(
        "MODULE.bazel", 'python = use_extension("@rules_python//python/extensions:python.bzl", "python")'
    ):
        py_toolchain.append('python = use_extension("@rules_python//python/extensions:python.bzl", "python")')

    # Introduce python default version only once.
    if not exists_in_file("MODULE.bazel", "python.defaults(python_version ="):
        py_toolchain.append(f'python.defaults(python_version = "{python_version}")')

    # Introduce python toolchain only once.
    if not exists_in_file("MODULE.bazel", f'python.toolchain(python_version = "{python_version}")'):
        py_toolchain.append(f'python.toolchain(python_version = "{python_version}")')

    py_toolchain_msg = "\n".join(py_toolchain)
    write_at_given_place(
        "MODULE.bazel",
        py_toolchain_msg,
        "# -- End of pip extensions -- #",
    )

    resolved("`" + repo + "` has been introduced as python extension, with python_version=" + python_version + ".")
    append_migration_info("## Migration of `" + repo + "`")
    append_migration_info("It has been introduced as a python extension, with python_version=" + python_version + ":\n")
    append_migration_info("```" + py_ext + "\n" + py_toolchain_msg + "\n```\n")


def address_unavailable_repo(repo, resolved_deps, workspace_name):
    # Check if it's the original main repo name
    if repo == workspace_name:
        error_message = []
        error_message.append(
            f"Please remove the usages of referring your own repo via `@{repo}//`, "
            "targets should be referenced directly with `//`. "
        )
        error_message.append(
            'If it\'s used in a macro, you can use `Label("//foo/bar")` '
            "to make sure it always points to your repo no matter where the macro is used."
        )
        error_message.append(
            "You can temporarily work around this by adding `repo_name` attribute "
            "to the `module` directive in your MODULE.bazel file."
        )
        error("\n".join(error_message))
        # TODO(kotlaja): Create more visible section for TODO.
        append_migration_info("TODO: " + "\n".join(error_message))

    # Print the repo definition in the original WORKSPACE file
    repo_def, file_label, rule_name, is_macro = [], None, None, False
    urls, maven_artifacts, origin_attrs, repositories = [], [], [], []
    for dep in resolved_deps:
        if dep["original_attributes"]["name"] == repo:
            repo_def, file_label, rule_name, is_macro = repo_definition(dep)
            origin_attrs = dep["original_attributes"]
            urls = origin_attrs.get("urls", [])
            if "artifacts" in origin_attrs:
                maven_artifacts = origin_attrs["artifacts"]
            if "repositories" in origin_attrs:
                repositories = origin_attrs["repositories"]
            if origin_attrs.get("url", None):
                urls.append(origin_attrs["url"])
            if origin_attrs.get("remote", None):
                urls.append(origin_attrs["remote"])
            break

    if not repo_def:
        msg = f"Repository definition for `{repo}` is not found in ./resolved_deps.py file, please add `--initial/-i` flag to force update it."
        error(msg)
        append_migration_info(msg)
        return False

    # Support go extension.
    if "bazel_gazelle" in file_label and "go_repository" in file_label:
        add_go_extension(repo, origin_attrs, resolved_deps, workspace_name)
        return True

    # Support maven extensions.
    if "rules_jvm_external" in file_label and maven_artifacts:
        add_maven_extension(repo, maven_artifacts, repositories, resolved_deps, workspace_name)
        return True

    # Support python extension.
    if "requirements_lock" in origin_attrs and "pip_repository" in file_label:
        add_python_extension(repo, origin_attrs, resolved_deps, workspace_name)
        return True

    if repo.startswith("pypi_") and "rules_python" in file_label:
        address_pypi_reference(repo)
        return False

    append_migration_info("## Migration of `" + repo + "`:")
    print_repo_definition(repo_def, dep)

    # Check if a module is already available in the registry.
    found_module = None
    potential_modules = []
    for module_name in REGISTRY_CLIENT.get_all_modules():
        if repo == module_name:
            found_module = module_name
            append_migration_info("Found perfect name match in BCR: `" + module_name + "`\n")
        elif any(url_match_source_repo(url, module_name) for url in urls):
            potential_modules.append(module_name)
    if potential_modules:
        append_migration_info("Found partially name matches in BCR: `" + "`, `".join(potential_modules) + ("`\n"))
    if found_module == None and len(potential_modules) > 0:
        found_module = potential_modules[0]

    if found_module:
        metadata = REGISTRY_CLIENT.get_metadata(found_module)
        version = metadata["versions"][-1]
        repo_name = "" if repo == found_module else f', repo_name = "{repo}"'
        bazel_dep_line = f'bazel_dep(name = "{found_module}", version = "{version}"{repo_name})'

        if not exists_in_file("MODULE.bazel", bazel_dep_line):
            if yes_or_no(
                "Do you wish to add the bazel_dep definition to the MODULE.bazel file?",
                True,
            ):
                append_migration_info("It has been introduced as a Bazel module:\n")
                append_migration_info("\t" + bazel_dep_line + "")
                resolved("`" + repo + "` has been introduced as a Bazel module.")
                write_at_given_place("MODULE.bazel", bazel_dep_line, BAZEL_DEP_IDENTIFIER)
                return True
        else:
            append_migration_info("This module has already been added inside the MODULE.bazel file")
            return True
    else:
        append_migration_info("\tIt is not found in BCR. \n")

    # Ask user if the dependency should be introduced via use_repo_rule
    # Only ask if the repo is defined in @bazel_tools or the root module to avoid potential cycle.
    if (
        file_label
        and not is_macro
        and file_label.startswith(("//", "@bazel_tools//"))
        and yes_or_no(
            "Do you wish to introduce the repository with use_repo_rule in MODULE.bazel (requires Bazel 7.3 or later)?",
            True,
        )
    ):
        append_migration_info("\tIt has been introduced with `use_repo_rule`:\n")
        resolved("`" + repo + "` has been introduced with `use_repo_rule`.")
        add_repo_with_use_repo_rule(repo, repo_def, file_label, rule_name)
        return True

    # Ask user if the dependency should be introduced via module extension
    # Only ask when file_label exists, which means it's a starlark repository rule.
    elif file_label and yes_or_no("Do you wish to introduce the repository with a module extension?", True):
        append_migration_info("It has been introduced using a module extension:\n")
        resolved("`" + repo + "` has been introduced using a module extension.")
        add_repo_to_module_extension(repo, repo_def, file_label, rule_name)
        return True
    elif rule_name == "local_repository" and repo != "bazel_tools":
        append_migration_info("It has been introduced using a module extension since it is local_repository rule:\n")
        resolved("`" + repo + "` has been introduced using a module extension (local_repository).")
        add_repo_to_module_extension(repo, repo_def, "@bazel_tools//tools/build_defs/repo:local.bzl", rule_name)
        return True

    append_migration_info("\tPlease manually add this dependency.")
    return False


def detect_bind_issue(stderr):
    """Search for error message that maybe caused by missing bind statements and return the missing target and its location."""
    for line in stderr.split("\n"):
        s = re.search(r"ERROR: (.*): no such package 'external':", line)
        if s:
            return s.groups()[0]
    return None


def address_bind_issue(bind_target_location, resolved_repos):
    print("")
    error(
        f"A bind target detected at {bind_target_location}! `bind` is already deprecated,"
        " you should reference the actual target directly instead of using //external:<target>"
        " (details at https://bazel.build/external/migration#bind-targets). After this fix, rerun this tool."
    )
    print("")


def address_pypi_reference(repo):
    repo_suffix = repo.removeprefix("pypi_")
    print("")
    error(
        f"Update pip dependency reference from @pypi_{repo_suffix}//:<pkg> to @pypi//{repo_suffix}."
        " The @pypi_<name> references are deprecated and the modern, supported, way is to go through the hub (@pypi)."
    )
    print("")


def extract_version_number(bazel_version):
    """Extracts the semantic version number from a version string
    Args:
      bazel_version: the version string that begins with the semantic version
        e.g. "1.2.3rc1 abc1234" where "abc1234" is a commit hash.
    Returns:
      The semantic version string, like "1.2.3".
    """
    for i in range(len(bazel_version)):
        c = bazel_version[i]
        if not (c.isdigit() or c == "."):
            return bazel_version[:i]
    return bazel_version


def parse_bazel_version(bazel_version):
    """Parses a version string into a 3-tuple of ints
    int tuples can be compared directly using binary operators (<, >).
    Args:
      bazel_version: the Bazel version string
    Returns:
      An int 3-tuple of a (major, minor, patch) version.
    """

    version = extract_version_number(bazel_version)
    return tuple([int(n) for n in version.split(".")])


def prepare_migration(initial_flag):
    """Preparation work before starting the migration."""
    exit_code, stdout, _ = execute_command(["bazel", "--version"])
    eprint(stdout.strip() + "\n")
    if exit_code != 0 or not stdout:
        warning(
            "Current bazel is not a release version, we recommend using Bazel 7 or newer releases for Bzlmod migration."
        )
    elif parse_bazel_version(stdout.strip().split(" ")[1]) < (6, 0, 0):
        error("Current Bazel version is too old, please upgrade to Bazel 7 or newer releases for Bzlmod migration.")
        abort_migration()

    # Parse the original workspace name from the WORKSPACE file
    workspace_name = "main"
    with open("WORKSPACE", "r") as f:
        for line in f:
            s = re.search(r"workspace\(name\s*=\s*[\'\"]([A-Za-z0-9_-]+)[\'\"]", line)
            if s:
                workspace_name = s.groups()[0]
                info(f"Detected original workspace name: {workspace_name}\n")

    # Delete MODULE.bazel file if `--initial` flag is set.
    if initial_flag:
        delete_file_if_exists("MODULE.bazel")
        delete_file_if_exists("migration_info.md")

    # Create MODULE.bazel file if it doesn't exist already.
    if not pathlib.Path("MODULE.bazel").is_file():
        scratch_file(
            "MODULE.bazel",
            [f'module(name = "{workspace_name}", version="")'],
        )
    module_bazel_content = open("MODULE.bazel", "r").read()
    for identifier in [
        BAZEL_DEP_IDENTIFIER,
        USE_REPO_RULE_IDENTIFIER,
        REPO_IDENTIFIER,
    ]:
        if identifier not in module_bazel_content:
            scratch_file("MODULE.bazel", ["", identifier], mode="a")

    return workspace_name


def generate_resolved_file(targets, use_bazel_sync):
    exit_code, _, stderr = execute_command(["bazel", "clean", "--expunge"])
    assertExitCode(exit_code, 0, "Failed to run `bazel clean --expunge`", stderr)
    bazel_nobuild_command = [
        "bazel",
        "build",
        "--nobuild",
        "--noenable_bzlmod",
        "--enable_workspace",
        "--experimental_repository_resolved_file=resolved_deps.py",
    ] + targets
    bazel_sync_comand = [
        "bazel",
        "sync",
        "--experimental_repository_resolved_file=resolved_deps.py",
    ]
    bazel_command = bazel_sync_comand if use_bazel_sync else bazel_nobuild_command
    exit_code, _, stderr = execute_command(bazel_command)
    assertExitCode(exit_code, 0, "Failed to run `" + " ".join(bazel_command) + "`", stderr)

    # Remove lines containing `"_action_listener":` in the resolved_deps.py file.
    # Avoiding https://github.com/bazelbuild/bazel-central-registry/issues/2789
    with open("resolved_deps.py", "r") as f:
        lines = f.readlines()
    with open("resolved_deps.py", "w") as f:
        for line in lines:
            if "unknown object com" not in line:
                f.write(line)


def load_resolved_deps(targets, use_bazel_sync, force):
    """Generate and load the resolved file that contains external deps info."""
    if not pathlib.Path("resolved_deps.py").is_file() or force:
        info("Generating ./resolved_deps.py file - It might take a while...")
        generate_resolved_file(targets, use_bazel_sync)
    else:
        info(
            "Found existing ./resolved_deps.py file - "
            "If it's out of date, please add `--initial/-i` flag to force update it."
        )

    spec = importlib.util.spec_from_file_location("resolved_deps", "./resolved_deps.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules["resolved_deps"] = module
    spec.loader.exec_module(module)
    resolved_deps = module.resolved
    return resolved_deps


def parse_file(filename):
    direct_deps = set()
    previous_line_has_external = False
    with open(filename, "r") as file:
        for line in file:
            # Parse for "@".
            matches_at = re.findall(r"@(\w+)//", line)
            for match_at in matches_at:
                if match_at != "bazel_tools" and not match_at.startswith("pypi_"):
                    direct_deps.add(match_at)

            # Parse for "/external/{repo_name}/".
            matches_external = re.findall(r"/external/(\w+)/", line)
            if previous_line_has_external == False:
                # Only first "/external/" is relevant.
                for match in matches_external:
                    if match != "bazel_tools":
                        direct_deps.add(match)
            previous_line_has_external = True if matches_external else False

    return direct_deps


def delete_file_if_exists(filename):
    """Deletes a file if it exists."""
    if os.path.exists(filename):
        try:
            os.remove(filename)
        except OSError as e:
            print(f"Error deleting file '{filename}': {e}")


def query_direct_targets(args):
    targets = args.target
    direct_deps_file = "query_direct_deps"
    delete_file_if_exists(direct_deps_file)

    for target in targets:
        bazel_command = ["bazel", "query", "--noenable_bzlmod", "--enable_workspace", "--output=build"] + [target]
        exit_code, stdout, stderr = execute_command(bazel_command)
        if exit_code != 0 or not stdout:
            error(
                "Bazel query: `"
                + " ".join(bazel_command)
                + "` contains error:\n"
                + stderr
                + "\nDouble check if the target you've specified can be built successfully."
            )
            abort_migration()
        append_to_file(direct_deps_file, stdout)

    direct_deps = parse_file(direct_deps_file)
    append_migration_info("## Direct dependencies:")
    append_migration_info("* " + "\n* ".join(map(str, direct_deps)))

    return direct_deps


def run_first_part(initial_flag):
    # Return true if MODULE.bazel file doesn't exist or if flag `--initial` is set.
    return not pathlib.Path("MODULE.bazel").is_file() or initial_flag


def get_error_target(stderr, init_target):
    pattern = r"Analysis of target '(.*?)' failed"
    match = re.search(pattern, stderr)
    if match:
        return match.group(1)
    else:
        return " ".join(init_target)


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    parser = argparse.ArgumentParser(
        prog="migrate_to_bzlmod",
        description="A helper script for migrating your external dependencies from WORKSPACE to Bzlmod. "
        + "For given targets, it first tries to generate a list of external dependencies for building your targets, "
        + "then tries to detect and add missing dependencies in the Bzlmod build. "
        + "You may still need to fix some problems manually.",
        epilog=(
            "Example usage: change into your project directory and run "
            "`<path to BCR repo>/tools/migrate_to_bzlmod.py --target //foo:bar`"
        ),
    )
    parser.add_argument(
        "-s",
        "--sync",
        action="store_true",
        help="use `bazel sync` instead of `bazel build --nobuild` to generate the resolved dependencies. "
        + "`bazel build --nobuild` only fetches dependencies needed for building specified targets, "
        + "while `bazel sync` resolves and fetches all dependencies defined in your WORKSPACE file, "
        + "including bind statements and execution platform & toolchain registrations.",
    )
    parser.add_argument(
        "-c",
        "--collaborate",
        action="store_true",
        help="collaborate with the user interactively on what to do.",
    )
    parser.add_argument(
        "-t",
        "--target",
        type=str,
        action="append",
        help="specify the targets you want to migrate. This flag is repeatable, and the targets are accumulated.",
    )
    parser.add_argument(
        "-i",
        "--initial",
        action="store_true",
        help="detect direct dependencies, introduce them in MODULE.bazel and rerun generation of resolved dependencies. Running with this flag always overrides the current MODULE.bazel file.",
    )

    args = parser.parse_args(argv)

    if not args.target:
        parser.print_help()
        return 1

    run_initial = run_first_part(args.initial)
    workspace_name = prepare_migration(args.initial)

    resolved_deps = load_resolved_deps(args.target, args.sync, args.initial)

    yes_or_no.enable = args.collaborate
    repro_command = "bazel build --enable_bzlmod --noenable_workspace " + " ".join(args.target)

    # First part of the migration - Find direct deps with bazel query and add them in MODULE.bazel file.
    if run_initial:
        append_migration_info("# Migration info")
        append_migration_info("Command for local testing:")
        append_migration_info("```\n" + repro_command + "\n```")
        print("")
        direct_deps = query_direct_targets(args)

        for direct_dep in direct_deps:
            if address_unavailable_repo(direct_dep, resolved_deps, workspace_name):
                continue
            else:
                important("Fix the error, then run this migration tool again.")
                print("")
                return 1
    else:
        info(
            "To create a MODULE.bazel file from scratch, either delete existing MODULE.bazel file or use the `--initial/-i` flag.\n"
        )

    # Second part of the migration - Build with bzlmod and fix potential errors.
    while True:
        # Try to build with Bzlmod enabled
        targets = args.target
        bazel_command = [
            "bazel",
            "build",
            "--nobuild",
            "--enable_bzlmod",
            "--noenable_workspace",
        ] + targets
        exit_code, _, stderr = execute_command(bazel_command)
        if exit_code == 0:
            print("")
            info(
                "Congratulations! All external repositories needed for building `"
                + " ".join(targets)
                + "` are available with Bzlmod!"
            )
            important("Fix potential build time issues by running the following command:")
            eprint(f"{BOLD}        `{repro_command}`{RESET}")
            break

        # 1. Detect build failure caused by unavailable repository
        repo = detect_unavailable_repo_error(stderr)
        if repo:
            if address_unavailable_repo(repo, resolved_deps, workspace_name):
                continue

        # 2. Detect build failure caused by unavailable bind statements
        bind_target_location = detect_bind_issue(stderr)
        if bind_target_location:
            if address_bind_issue(bind_target_location, resolved_deps):
                continue

        print("")
        error("Unrecognized error, please fix manually:\n" + stderr)
        err_target = get_error_target(stderr, args.target)
        important("Fix the error, then run this migration tool again. Command for reproducing the error:")
        eprint(f"{BOLD}    `bazel build --enable_bzlmod --noenable_workspace {err_target}`{RESET}\n")
        return 1

    print("")
    important("For details about the migration process, check `migration_info.md` file.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
