"""Hermetic FBThrift code generation for CacheLib's pinned schemas."""

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

_FROZEN2_SUFFIXES = _COMMON_SUFFIXES + [
    "layouts.cpp",
    "layouts.h",
]

def _generated_files(output_dir, module, suffixes):
    return ["{}/gen-cpp2/{}_{}".format(output_dir, module, suffix) for suffix in suffixes]

def cachelib_thrift_library(
        name,
        thrift_src,
        thrift_path,
        output_dir,
        module,
        generator_option = None,
        frozen2 = False,
        deps = []):
    """Generates and compiles one CacheLib schema without source-tree outputs."""
    suffixes = _FROZEN2_SUFFIXES if frozen2 else _COMMON_SUFFIXES
    outputs = _generated_files(output_dir, module, suffixes)
    headers = [output for output in outputs if not output.endswith(".cpp")]
    sources = [
        output
        for output in outputs
        if output.endswith(".cpp") and not output.endswith("_sinit.cpp")
    ]
    generator = "mstch_cpp2"
    if generator_option:
        generator += ":" + generator_option

    native.genrule(
        name = name + "_codegen",
        srcs = [
            thrift_src,
            ":README.md",
            ":thrift_includes",
            "@fbthrift_cachelib//:README.md",
            "@fbthrift_cachelib//:thrift_includes",
        ],
        outs = outputs,
        cmd = ("EXEC_ROOT=$$PWD && " +
               "CACHELIB_ROOT=$$EXEC_ROOT/$$(dirname $(location :README.md)) && " +
               "FBTHRIFT_ROOT=$$EXEC_ROOT/$$(dirname $(location @fbthrift_cachelib//:README.md)) && " +
               "mkdir -p $$EXEC_ROOT/$(RULEDIR)/{output_dir} && " +
               "cd $$CACHELIB_ROOT && " +
               "$$EXEC_ROOT/$(location @fbthrift_cachelib//:thrift1) " +
               "-o $$EXEC_ROOT/$(RULEDIR)/{output_dir} --gen {generator} " +
               "-I $$CACHELIB_ROOT " +
               "-I $$FBTHRIFT_ROOT " +
               "{thrift_path}").format(
            generator = generator,
            output_dir = output_dir,
            thrift_path = thrift_path,
        ),
        tools = ["@fbthrift_cachelib//:thrift1"],
    )

    cc_library(
        name = name + "_headers",
        hdrs = headers,
        strip_include_prefix = "generated",
        deps = ["@fbthrift_cachelib//:protocol"] + deps,
    )

    cc_library(
        name = name,
        srcs = sources,
        deps = [name + "_headers"],
    )
