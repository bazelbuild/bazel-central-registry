"""Hermetic code generation for FBThrift's pinned runtime schemas."""

load("@rules_cc//cc:defs.bzl", "cc_library")

_COMMON_SUFFIXES = [
    "clients.h",
    "clients_fwd.h",
    "constants.cpp",
    "constants.h",
    "data.cpp",
    "data.h",
    "for_each_field.h",
    "handlers.h",
    "metadata.cpp",
    "metadata.h",
    "sinit.cpp",
    "types.cpp",
    "types.h",
    "types.tcc",
    "types_binary.cpp",
    "types_compact.cpp",
    "types_custom_protocol.h",
    "types_fwd.h",
    "types_serialization.cpp",
    "visit_by_thrift_field_metadata.h",
    "visit_union.h",
    "visitation.h",
]

def fbthrift_library(name, thrift_src, thrift_path, output_dir, module):
    """Generates and compiles one schema without source-tree outputs."""
    outputs = [
        "{}/gen-cpp2/{}_{}".format(output_dir, module, suffix)
        for suffix in _COMMON_SUFFIXES
    ]
    headers = [output for output in outputs if not output.endswith(".cpp")]
    sources = [
        output
        for output in outputs
        if output.endswith(".cpp") and not output.endswith("_sinit.cpp")
    ]

    native.genrule(
        name = name + "_codegen",
        srcs = [
            thrift_src,
            ":README.md",
            ":thrift_includes",
        ],
        outs = outputs,
        cmd = ("EXEC_ROOT=$$PWD && " +
               "FBTHRIFT_ROOT=$$EXEC_ROOT/$$(dirname $(location :README.md)) && " +
               "mkdir -p $$EXEC_ROOT/$(RULEDIR)/{output_dir} && " +
               "cd $$FBTHRIFT_ROOT && " +
               "$$EXEC_ROOT/$(location :thrift1) " +
               "-o $$EXEC_ROOT/$(RULEDIR)/{output_dir} --gen mstch_cpp2 " +
               "-I $$FBTHRIFT_ROOT {thrift_path}").format(
            output_dir = output_dir,
            thrift_path = thrift_path,
        ),
        tools = [":thrift1"],
    )

    cc_library(
        name = name + "_headers",
        hdrs = headers,
        strip_include_prefix = "generated",
        deps = [":protocol"],
    )

    cc_library(
        name = name,
        srcs = sources,
        deps = [name + "_headers"],
    )
