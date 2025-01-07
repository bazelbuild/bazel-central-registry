load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@rules_cc//cc:defs.bzl", "cc_library")

def stb_library(header):
    target_name = header.split(".")[0]
    c_file = target_name + ".c"
    stb_define = "{}_IMPLEMENTATION".format(target_name.upper())

    expand_template(
        name = target_name + "_template",
        out = c_file,
        substitutions = {
            "@DEFINE@": stb_define,
            "@HEADER@": header,
        },
        template = "stb_template.c.in",
    )

    cc_library(
        name = target_name,
        hdrs = [header],
        srcs = [c_file],
        local_defines = [stb_define],
        includes = ["."],
        visibility = ["//visibility:public"],
    )
