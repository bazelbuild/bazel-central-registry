"""Macro for creating Yosys .ys script regression tests."""

load("@rules_python//python:py_test.bzl", "py_test")

def yosys_ys_tests(ys_files, data = [], tags = [], size = "small"):
    """Create one py_test per .ys script file.

    Args:
        ys_files: list of .ys file labels (typically from glob(["dir/*.ys"]))
        data: additional data files needed by the tests (e.g. sibling .v files)
        tags: Bazel tags to apply to each test
        size: Bazel test size (default "small")
    """
    for ys_file in ys_files:
        # Derive a valid Bazel target name from the file path.
        # e.g. "opt/bug2221.ys" -> "ys_opt__bug2221"
        test_name = "ys_" + ys_file.replace("/", "__").replace(".", "_")

        py_test(
            name = test_name,
            srcs = [":run_ys_test.py"],
            main = "run_ys_test.py",
            data = data + [ys_file, "@yosys"],
            env = {
                "YOSYS": "$(rlocationpath @yosys)",
                "YS_SCRIPT": "$(rlocationpath " + ys_file + ")",
            },
            tags = tags,
            size = size,
        )
