"""Helper for porting the upstream Makefile `quicktest` cases to Bazel."""

load("@bazel_skylib//rules:diff_test.bzl", "diff_test")

def quicktest(name, expected, flags = [], inputs = []):
    """One quicktest case: generate trec_eval output, then diff it.

    Runs `trec_eval <flags> <inputs>` and compares stdout against `expected`,
    mirroring a single `... | diff - <expected>` line of `make quicktest`.

    Args:
        name: test target name.
        expected: checked-in golden file to compare against.
        flags: trec_eval command-line flags, one token per list element.
        inputs: input data files, appended after the flags in order.
    """
    refs = ["$(execpath {})".format(f) for f in inputs]
    native.genrule(
        name = name + "_gen",
        srcs = inputs,
        outs = [name + ".actual"],
        tools = ["@trec_eval//:trec_eval"],
        cmd = "$(execpath @trec_eval//:trec_eval) {} {} > $@".format(
            " ".join(flags),
            " ".join(refs),
        ),
        testonly = True,
    )
    diff_test(
        name = name,
        file1 = expected,
        file2 = name + ".actual",
    )
