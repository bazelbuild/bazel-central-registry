load("@npm//:defs.bzl", "npm_link_all_packages")
load("@pip//:requirements.bzl", "requirement")
load("@python_versions//3.11:defs.bzl", compile_pip_requirements_3_11 = "compile_pip_requirements")
load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")

npm_link_all_packages(name = "node_modules")

compile_pip_requirements_3_11(
    name = "requirements",
    requirements_in = "requirements.in",
    requirements_txt = "requirements_lock.txt",
)

py_binary(
    name = "add_module",
    srcs = ["add_module.py"],
    deps = [
        ":bcr_validation",
        ":registry",
    ],
)

py_binary(
    name = "calc_integrity",
    srcs = ["calc_integrity.py"],
    deps = [
        ":registry",
        requirement("validators"),
    ],
)

py_binary(
    name = "migrate_to_bzlmod",
    srcs = ["migrate_to_bzlmod.py"],
    deps = [
        ":registry",
    ],
)

py_binary(
    name = "print_all_src_urls",
    srcs = ["print_all_src_urls.py"],
    deps = [
        ":registry",
    ],
)

py_binary(
    name = "bcr_validation",
    srcs = ["bcr_validation.py"],
    deps = [
        ":registry",
        ":verify_stable_archives",
    ],
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

py_binary(
    name = "update_integrity",
    srcs = ["update_integrity.py"],
    deps = [
        ":registry",
        requirement("click"),
    ],
)

py_binary(
    name = "module_selector",
    srcs = ["module_selector.py"],
    deps = [
        ":registry",
    ],
)

py_binary(
    name = "module_analyzer",
    srcs = ["module_analyzer.py"],
    deps = [
        ":module_selector",
        requirement("networkx"),
        requirement("numpy"),
        requirement("scipy"),
        requirement("bazel-runfiles"),
    ],
    data = [
        "@buildozer_binary//:buildozer.exe",
    ]
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
    name = "version_test",
    srcs = [
        "version_test.py",
    ],
    deps = [
        "registry",
    ],
)

py_test(
    name = "module_selector_test",
    srcs = [
        "module_selector_test.py",
    ],
    deps = [
        "module_selector",
    ],
)
