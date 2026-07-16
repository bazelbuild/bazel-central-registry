load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")

def libarchive_test(name = None, tests = None, data = None, deps = [], **kwargs):
    if not tests:
        tests = [name]
    if not data:
        data = native.glob(["*.uu"])
    write_file(
        name = "{}_list_h".format(name),
        out = "_{}_list_h/list.h".format(name),
        content = ["DEFINE_TEST({})".format(test) for test in tests],
    )
    cc_library(
        name = "{}_list".format(name),
        hdrs = ["_{}_list_h/list.h".format(name)],
        strip_include_prefix = "_{}_list_h".format(name),
    )
    cc_test(
        name = name,
        includes = ["."],
        srcs = ["//test_utils:test_main.c"] + ["{}.c".format(name)],
        data = data,
        deps = deps + [
            ":{}_list".format(name),
            "//test_utils:common",
            "//libarchive",
            "//libarchive:internal_hdrs",
        ],
        **kwargs
    )
