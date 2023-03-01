load("@rules_python//python:defs.bzl", "py_binary", "py_library")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")
load("@tools_deps//:requirements.bzl", "requirement")

compile_pip_requirements(
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

py_library(
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

py_test(
    name = "version_test",
    srcs = [
      "version_test.py",
    ],
    deps = [
      "registry", 
    ],
)
