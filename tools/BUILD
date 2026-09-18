load("@npm//:defs.bzl", "npm_link_all_packages")
load("@pip//:requirements.bzl", "requirement")
load("@python_versions//3.11:defs.bzl", compile_pip_requirements_3_11 = "compile_pip_requirements")
load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

npm_link_all_packages(name = "node_modules")

compile_pip_requirements_3_11(
    name = "requirements",
    requirements_in = "requirements.in",
    requirements_txt = "requirements_lock.txt",
)

py_binary(
    name = "add_module",
    srcs = ["add_module.py"],
    legacy_create_init = 0,
    deps = [
        ":bcr_validation",
        ":registry",
    ],
)

py_binary(
    name = "calc_integrity",
    srcs = ["calc_integrity.py"],
    legacy_create_init = 0,
    deps = [
        ":registry",
        requirement("validators"),
    ],
)

py_binary(
    name = "migrate_to_bzlmod",
    srcs = ["migrate_to_bzlmod.py"],
    legacy_create_init = 0,
    deps = [
        ":registry",
    ],
)

py_binary(
    name = "print_all_src_urls",
    srcs = ["print_all_src_urls.py"],
    legacy_create_init = 0,
    deps = [
        ":registry",
    ],
)

py_binary(
    name = "bcr_validation",
    srcs = ["bcr_validation.py"],
    legacy_create_init = 0,
    deps = [
        ":attestations",
        ":registry",
        ":slsa",
        ":verify_stable_archives",
        requirement("requests"),
        requirement("zstandard"),
    ],
)

py_test(
    name = "bcr_validation_test",
    srcs = ["bcr_validation_test.py"],
    legacy_create_init = 0,
    deps = [":bcr_validation"],
)

py_library(
    name = "verify_stable_archives",
    srcs = ["verify_stable_archives.py"],
)

py_library(
    name = "registry",
    srcs = ["registry.py"],
    imports = ["."],
    deps = [
        requirement("pyyaml"),
    ],
)

py_library(
    name = "attestations",
    srcs = ["attestations.py"],
    imports = ["."],
)

py_library(
    name = "slsa",
    srcs = ["slsa.py"],
    imports = ["."],
    deps = [
        ":attestations",
    ],
)

py_binary(
    name = "update_integrity",
    srcs = ["update_integrity.py"],
    legacy_create_init = 0,
    deps = [
        ":registry",
        requirement("click"),
    ],
)

py_binary(
    name = "module_selector",
    srcs = ["module_selector.py"],
    legacy_create_init = 0,
    deps = [
        ":registry",
    ],
)

py_binary(
    name = "module_analyzer",
    srcs = ["module_analyzer.py"],
    data = [
        "@buildozer_binary//:buildozer.exe",
    ],
    legacy_create_init = 0,
    deps = [
        ":module_selector",
        requirement("networkx"),
        requirement("numpy"),
        requirement("scipy"),
        requirement("bazel-runfiles"),
    ],
)

py_binary(
    name = "mcp_server",
    srcs = ["mcp_server.py"],
    legacy_create_init = 0,
    deps = [
        ":registry",
        requirement("fastmcp"),
    ],
)

genrule(
    name = "bazelci_py",
    srcs = ["@bazelci_py_file//file"],
    outs = ["bazelci.py"],
    cmd = "cp $(location @bazelci_py_file//file) $@",
)

genrule(
    name = "bcr_presubmit_py",
    srcs = ["@bcr_presubmit_py_file//file"],
    outs = ["bcr_presubmit.py"],
    cmd = "cp $(location @bcr_presubmit_py_file//file) $@",
)

py_library(
    name = "bazelci",
    srcs = ["bazelci.py"],
)

py_library(
    name = "bcr_presubmit",
    srcs = ["bcr_presubmit.py"],
    deps = [
        ":bazelci",
        requirement("requests"),
        requirement("pyyaml"),
    ],
)

py_binary(
    name = "setup_presubmit_repos",
    srcs = ["setup_presubmit_repos.py"],
    imports = ["."],
    legacy_create_init = 0,
    deps = [
        ":bcr_presubmit",
    ],
)

sh_test(
    name = "update_integrity_test",
    srcs = ["update_integrity_test.sh"],
    data = [":update_integrity"],
)

py_test(
    name = "registry_test",
    size = "small",
    srcs = [
        "registry_test.py",
    ],
    legacy_create_init = 0,
    deps = [
        "registry",
    ],
)

py_test(
    name = "version_test",
    srcs = [
        "version_test.py",
    ],
    legacy_create_init = 0,
    deps = [
        "registry",
    ],
)

py_test(
    name = "module_selector_test",
    srcs = [
        "module_selector_test.py",
    ],
    legacy_create_init = 0,
    deps = [
        "module_selector",
    ],
)

py_test(
    name = "ci_metadata_isolation_canary",
    srcs = ["ci_metadata_isolation_canary.py"],
    tags = ["no-sandbox"],
)
