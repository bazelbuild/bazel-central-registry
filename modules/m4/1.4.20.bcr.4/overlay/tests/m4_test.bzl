"""Macro for end-to-end m4 integration tests."""

load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def m4_test(
        *,
        name,
        input,
        expected,
        m4 = "//:m4",
        m4_flags = [],
        **kwargs):
    """Runs m4 on inline input and verifies stdout matches expected output.

    Creates four targets:
      - `<name>_input`: a write_file producing the .m4 input.
      - `<name>_expected`: a write_file producing the expected output.
      - `<name>_gen`: a genrule that invokes m4 and captures stdout.
      - `<name>`: a diff_test comparing actual vs expected output.

    Args:
        name: Name of the diff_test target.
        input: List of strings forming the m4 input (one per line).
        expected: List of strings forming the expected stdout (one per line).
        m4: Label of the m4 binary to use.
        m4_flags: Additional command-line flags passed to m4.
        **kwargs: Forwarded to diff_test.
    """
    write_file(
        name = name + "_input",
        out = name + ".m4",
        content = input,
        newline = "unix",
        tags = ["manual"],
    )

    write_file(
        name = name + "_expected",
        out = name + "_expected.txt",
        content = expected,
        newline = "unix",
        tags = ["manual"],
    )

    flags = " ".join(m4_flags)
    if flags:
        flags += " "

    native.genrule(
        name = name + "_gen",
        srcs = [":" + name + "_input"],
        outs = [name + "_actual.txt"],
        cmd = "$(execpath {m4}) {flags}$(SRCS) > $@".format(m4 = m4, flags = flags),
        cmd_bat = "$(execpath {m4}) {flags}$(SRCS) > $@".format(m4 = m4, flags = flags),
        tools = [m4],
        testonly = True,
    )

    diff_test(
        name = name,
        file1 = ":" + name + "_gen",
        file2 = ":" + name + "_expected",
        **kwargs
    )
