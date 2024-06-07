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
