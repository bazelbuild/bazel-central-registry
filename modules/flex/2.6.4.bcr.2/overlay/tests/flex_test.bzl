"""Macro for wiring up flex scanner tests."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_test.bzl", "cc_test")
load("//:flex.bzl", "flex")

def flex_test(*, name, src, input):
    """Build a scanner from a .l file and test it with stdin input.

    Mirrors the native test suite pattern:
        flex -o scanner.c scanner.l
        cc -DHAVE_CONFIG_H scanner.c -o scanner
        ./scanner < scanner.txt

    Args:
        name: Base name for the test (targets: gen_{name}, {name}_bin, test_{name}).
        src: The .l flex input file.
        input: The .txt file to pipe to stdin.
    """
    gen_name = "gen_" + name
    bin_name = name + "_bin"
    out_file = name + "_gen.c"

    flex(
        name = gen_name,
        srcs = [src],
        outs = [out_file],
        args = ["-o", "$(execpath " + out_file + ")", "$(execpath " + src + ")"],
        testonly = True,
    )

    cc_binary(
        name = bin_name,
        srcs = [":" + gen_name],
        copts = ["-DHAVE_CONFIG_H"] + select({
            "@platforms//os:windows": ["-DYY_NO_UNISTD_H"],
            "//conditions:default": [],
        }),
        deps = [Label("//:config")],
        testonly = True,
    )

    cc_test(
        name = "test_" + name,
        srcs = ["test_runner.cc"],
        data = [
            ":" + bin_name,
            input,
        ],
        args = [
            "$(rlocationpath :" + bin_name + ")",
            "$(rlocationpath " + input + ")",
        ],
        deps = ["@rules_cc//cc/runfiles"],
    )
