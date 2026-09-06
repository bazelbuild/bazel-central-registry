"""Hermetic code generation using FBThrift's pinned compiler and runtime."""

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

_COMPILER = Label("//:thrift1")
_FBTHRIFT_INCLUDES = Label("//:thrift_includes")
_FBTHRIFT_ROOT = Label("//:README.md")
_PROTOCOL = Label("//:protocol")

def _generated_files(output_dir, module, suffixes):
    return ["{}/gen-cpp2/{}_{}".format(output_dir, module, suffix) for suffix in suffixes]

def fbthrift_library(
        name,
        thrift_src,
        thrift_path,
        output_dir,
        module,
        generator_option = None,
        frozen2 = False,
        deps = [],
        source_includes = None,
        source_root = None):
    """Generates and compiles one schema without source-tree outputs."""
    source_includes = source_includes or _FBTHRIFT_INCLUDES
    source_root = source_root or _FBTHRIFT_ROOT
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

    srcs = [
        thrift_src,
        source_root,
        source_includes,
    ]
    root_setup = "THRIFT_ROOT=$$EXEC_ROOT/$$(dirname $(location {})) && ".format(source_root)
    include_flags = "-I $$THRIFT_ROOT"
    if source_root != _FBTHRIFT_ROOT:
        srcs.extend([
            _FBTHRIFT_ROOT,
            _FBTHRIFT_INCLUDES,
        ])
        root_setup += "FBTHRIFT_ROOT=$$EXEC_ROOT/$$(dirname $(location {})) && ".format(_FBTHRIFT_ROOT)
        include_flags += " -I $$FBTHRIFT_ROOT"

    native.genrule(
        name = name + "_codegen",
        srcs = srcs,
        outs = outputs,
        cmd = ("EXEC_ROOT=$$PWD && " +
               root_setup +
               "mkdir -p $$EXEC_ROOT/$(RULEDIR)/{output_dir} && " +
               "cd $$THRIFT_ROOT && " +
               "$$EXEC_ROOT/$(location {compiler}) " +
               "-o $$EXEC_ROOT/$(RULEDIR)/{output_dir} --gen {generator} " +
               "{include_flags} {thrift_path}").format(
            compiler = _COMPILER,
            generator = generator,
            include_flags = include_flags,
            output_dir = output_dir,
            thrift_path = thrift_path,
        ),
        tools = [_COMPILER],
    )

    cc_library(
        name = name + "_headers",
        hdrs = headers,
        strip_include_prefix = "generated",
        deps = [_PROTOCOL] + deps,
    )

    cc_library(
        name = name,
        srcs = sources,
        deps = [name + "_headers"],
    )
