"""Native Bazel build graph for the Doxygen source archive."""

load("@bison//:bison.bzl", "bison")
load("@flex//:flex.bzl", "flex")
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")
load("@rules_python//python:defs.bzl", "py_binary")

_LEXERS = [
    "code",
    "commentcnv",
    "commentscan",
    "constexp",
    "configimpl",
    "declinfo",
    "defargs",
    "doctokenizer",
    "fortrancode",
    "fortranscanner",
    "lexcode",
    "lexscanner",
    "pre",
    "pycode",
    "pyscanner",
    "scanner",
    "sqlcode",
    "vhdlcode",
    "xmlcode",
]

_COMMON_INCLUDES = [
    "deps/TinyDeflate",
    "deps/filesystem",
    "deps/fmt/include",
    "deps/liblodepng",
    "deps/libmd5",
    "deps/libmscgen",
    "deps/spdlog/include",
    "deps/sqlite3",
    "libversion",
    "libxml",
    "src",
    "vhdlparser",
    "generated",
]

_COMMON_COPTS = [
    "-DJAVACC_CHAR_TYPE=\"char\"",
    "-DYY_BUF_SIZE=262144",
    "-DYY_READ_BUF_SIZE=262144",
]

_COMMON_CXXOPTS = [
    "-std=gnu++17",
]

_DEFAULT_DOXYGEN_VERSION = "1.18.0"

def _generated_label(name):
    return ":generated/%s" % name

def _shell_quote(value):
    return "'%s'" % value.replace("'", "'\"'\"'")

def _python_action_impl(ctx):
    inputs = [file for target in ctx.attr.inputs for file in target.files.to_list()]
    outputs = ctx.outputs.outs
    kind = ctx.attr.kind

    if kind == "pre_lex":
        args = [inputs[0].path] + [output.path for output in outputs] + [inputs[0].dirname]
    elif kind == "post_lex":
        args = [
            ctx.file.intermediate.path,
            outputs[0].path,
            ctx.file.correction.path,
            ctx.file.original.path,
            ctx.file.generated.path,
        ]
    elif kind == "config":
        args = [ctx.attr.mode, inputs[0].path, outputs[0].path]
    elif kind == "vhdl":
        args = [inputs[0].path, outputs[0].path]
    elif kind == "resources":
        template_root = ctx.file.sentinel.path.rsplit("/", 2)[0]
        args = [template_root, outputs[0].path]
    else:
        fail("Unknown Doxygen Python action kind: %s" % kind)

    if kind == "config":
        ctx.actions.run_shell(
            command = "{} {} {} > {}".format(
                _shell_quote(ctx.executable.tool.path),
                _shell_quote(args[0]),
                _shell_quote(args[1]),
                _shell_quote(args[2]),
            ),
            inputs = inputs,
            outputs = outputs,
            tools = [ctx.attr.tool[DefaultInfo].files_to_run],
            mnemonic = "DoxygenConfig",
            progress_message = "Generating Doxygen %s" % args[0],
        )
    else:
        ctx.actions.run(
            executable = ctx.executable.tool,
            arguments = args,
            inputs = inputs,
            outputs = outputs,
            tools = [ctx.attr.tool[DefaultInfo].files_to_run],
            mnemonic = "Doxygen%s" % kind.title().replace("_", ""),
            progress_message = "Generating Doxygen %s" % kind,
        )
    return [DefaultInfo(files = depset(outputs))]

_python_action = rule(
    implementation = _python_action_impl,
    attrs = {
        "inputs": attr.label_list(allow_files = True),
        "correction": attr.label(allow_single_file = True),
        "generated": attr.label(allow_single_file = True),
        "intermediate": attr.label(allow_single_file = True),
        "kind": attr.string(mandatory = True),
        "mode": attr.string(),
        "original": attr.label(allow_single_file = True),
        "outs": attr.output_list(mandatory = True),
        "sentinel": attr.label(allow_single_file = True),
        "tool": attr.label(cfg = "exec", executable = True, mandatory = True),
    },
)

def _scan_states_impl(ctx):
    input_file = ctx.files.src[0]
    output = ctx.outputs.out
    ctx.actions.run_shell(
        command = "{} {} > {}".format(
            _shell_quote(ctx.executable.tool.path),
            _shell_quote(input_file.path),
            _shell_quote(output.path),
        ),
        inputs = [input_file],
        outputs = [output],
        tools = [ctx.attr.tool[DefaultInfo].files_to_run],
        mnemonic = "DoxygenScanStates",
        progress_message = "Generating Doxygen scanner state header",
    )
    return [DefaultInfo(files = depset([output]))]

_scan_states = rule(
    implementation = _scan_states_impl,
    attrs = {
        "out": attr.output(mandatory = True),
        "src": attr.label_list(allow_files = True, mandatory = True),
        "tool": attr.label(cfg = "exec", executable = True, mandatory = True),
    },
)

def _write_file_impl(ctx):
    output = ctx.outputs.out
    ctx.actions.write(output = output, content = ctx.attr.content)
    return [DefaultInfo(files = depset([output]))]

_write_file = rule(
    implementation = _write_file_impl,
    attrs = {
        "content": attr.string(mandatory = True),
        "out": attr.output(mandatory = True),
    },
)

def _expand_template_impl(ctx):
    output = ctx.outputs.out
    ctx.actions.expand_template(
        output = output,
        template = ctx.file.template,
        substitutions = ctx.attr.substitutions,
    )
    return [DefaultInfo(files = depset([output]))]

_expand_template = rule(
    implementation = _expand_template_impl,
    attrs = {
        "out": attr.output(mandatory = True),
        "substitutions": attr.string_dict(),
        "template": attr.label(allow_single_file = True, mandatory = True),
    },
)

def _make_python_tools():
    py_binary(
        name = "configgen",
        srcs = ["src/configgen.py"],
        main = "src/configgen.py",
    )
    py_binary(
        name = "post_lex",
        srcs = ["src/post_lex.py"],
        main = "src/post_lex.py",
    )
    py_binary(
        name = "pre_lex",
        srcs = ["src/pre_lex.py"],
        main = "src/pre_lex.py",
    )
    py_binary(
        name = "res2cc_cmd",
        srcs = ["src/res2cc_cmd.py"],
        main = "src/res2cc_cmd.py",
    )
    py_binary(
        name = "scan_states",
        srcs = ["src/scan_states.py"],
        main = "src/scan_states.py",
    )
    py_binary(
        name = "vhdl_adj",
        srcs = ["vhdlparser/vhdl_adj.py"],
        main = "vhdlparser/vhdl_adj.py",
    )

def _make_lexer(lexer):
    _python_action(
        name = "generated_%s_inputs" % lexer,
        inputs = ["src/%s.l" % lexer],
        kind = "pre_lex",
        outs = [
            "generated/%s.l" % lexer,
            "generated/%s.corr" % lexer,
            "generated/%s.d" % lexer,
        ],
        tool = ":pre_lex",
    )
    flex(
        name = "generated_%s_flex" % lexer,
        srcs = [_generated_label("%s.l" % lexer)],
        outs = ["generated/%s_intermediate.cpp" % lexer],
        args = [
            "-o",
            "$(execpath generated/%s_intermediate.cpp)" % lexer,
            "$(execpath generated/%s.l)" % lexer,
        ],
    )
    _python_action(
        name = "generated_%s_cpp" % lexer,
        inputs = [
            _generated_label("%s_intermediate.cpp" % lexer),
            _generated_label("%s.corr" % lexer),
            "src/%s.l" % lexer,
            _generated_label("%s.l" % lexer),
        ],
        kind = "post_lex",
        correction = _generated_label("%s.corr" % lexer),
        generated = _generated_label("%s.l" % lexer),
        intermediate = _generated_label("%s_intermediate.cpp" % lexer),
        original = "src/%s.l" % lexer,
        outs = ["generated/%s.cpp" % lexer],
        tool = ":post_lex",
    )
    _scan_states(
        name = "generated_%s_states" % lexer,
        src = [_generated_label("%s.l" % lexer)],
        out = "generated/%s.l.h" % lexer,
        tool = ":scan_states",
    )

def doxygen_native(version = _DEFAULT_DOXYGEN_VERSION):
    """Defines the native Doxygen executable and its generated inputs."""
    _make_python_tools()

    _write_file(
        name = "generated_settings_h",
        out = "generated/settings.h",
        content = "#ifndef SETTINGS_H\n#define SETTINGS_H\n#define USE_LIBCLANG 0\n#define IS_SUPPORTED(x) 0\n#endif\n",
    )
    _python_action(
        name = "generated_configvalues_h",
        inputs = ["src/config.xml"],
        kind = "config",
        mode = "-maph",
        outs = ["generated/configvalues.h"],
        tool = ":configgen",
    )
    _python_action(
        name = "generated_configvalues_cpp",
        inputs = ["src/config.xml"],
        kind = "config",
        mode = "-maps",
        outs = ["generated/configvalues.cpp"],
        tool = ":configgen",
    )
    _python_action(
        name = "generated_configoptions_cpp",
        inputs = ["src/config.xml"],
        kind = "config",
        mode = "-cpp",
        outs = ["generated/configoptions.cpp"],
        tool = ":configgen",
    )
    _python_action(
        name = "generated_resources_cpp",
        inputs = native.glob(["templates/**"]),
        kind = "resources",
        outs = ["generated/resources.cpp"],
        sentinel = "templates/html/header.html",
        tool = ":res2cc_cmd",
    )

    for lexer in _LEXERS:
        _make_lexer(lexer)

    bison(
        name = "generated_ce_parse",
        srcs = ["src/constexp.y"],
        outs = [
            "generated/ce_parse.cpp",
            "generated/ce_parse.hpp",
        ],
        args = [
            "--defines=$(execpath generated/ce_parse.hpp)",
            "-o",
            "$(execpath generated/ce_parse.cpp)",
            "$(execpath src/constexp.y)",
        ],
    )

    bison(
        name = "generated_mscgen_language",
        srcs = ["deps/libmscgen/mscgen_language.y"],
        outs = ["generated/mscgen_language.cpp"],
        args = [
            "-o",
            "$(execpath generated/mscgen_language.cpp)",
            "$(execpath deps/libmscgen/mscgen_language.y)",
        ],
    )

    flex(
        name = "generated_mscgen_lexer",
        srcs = ["deps/libmscgen/mscgen_lexer.l"],
        outs = ["generated/mscgen_lexer.cpp"],
        args = [
            "-o",
            "$(execpath generated/mscgen_lexer.cpp)",
            "$(execpath deps/libmscgen/mscgen_lexer.l)",
        ],
    )
    _scan_states(
        name = "generated_mscgen_lexer_states",
        src = ["deps/libmscgen/mscgen_lexer.l"],
        out = "generated/mscgen_lexer.l.h",
        tool = ":scan_states",
    )

    flex(
        name = "generated_xml",
        srcs = ["libxml/xml.l"],
        outs = ["generated/xml.cpp"],
        args = [
            "-o",
            "$(execpath generated/xml.cpp)",
            "$(execpath libxml/xml.l)",
        ],
    )
    _scan_states(
        name = "generated_xml_states",
        src = ["libxml/xml.l"],
        out = "generated/xml.l.h",
        tool = ":scan_states",
    )

    _python_action(
        name = "generated_vhdl_parser",
        inputs = ["vhdlparser/VhdlParser.cc"],
        kind = "vhdl",
        outs = ["generated/VhdlParser_adj.cc"],
        tool = ":vhdl_adj",
    )
    _python_action(
        name = "generated_vhdl_token_manager",
        inputs = ["vhdlparser/VhdlParserTokenManager.cc"],
        kind = "vhdl",
        outs = ["generated/VhdlParserTokenManager_adj.cc"],
        tool = ":vhdl_adj",
    )

    _expand_template(
        name = "generated_doxyversion",
        template = "libversion/doxyversion.cpp.in",
        out = "generated/doxyversion.cpp",
        substitutions = {"@DOXYGEN_VERSION@": version},
    )
    _expand_template(
        name = "generated_gitversion",
        template = "libversion/gitversion.cpp.in",
        out = "generated/gitversion.cpp",
        substitutions = {
            "@GIT_HEAD_SHA1@": "GIT-NOTFOUND",
            "@GIT_IS_DIRTY@": "false",
        },
    )

    cc_library(
        name = "md5",
        srcs = ["deps/libmd5/md5.c"],
        hdrs = native.glob(["deps/libmd5/*.h"]),
        includes = _COMMON_INCLUDES,
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = "lodepng",
        srcs = ["deps/liblodepng/lodepng.cpp"],
        hdrs = ["deps/liblodepng/lodepng.h"],
        copts = _COMMON_COPTS,
        cxxopts = _COMMON_CXXOPTS,
        includes = _COMMON_INCLUDES,
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = "sqlite3",
        srcs = ["deps/sqlite3/sqlite3.c"],
        hdrs = ["deps/sqlite3/sqlite3.h"],
        includes = _COMMON_INCLUDES,
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = "spdlog",
        srcs = native.glob(["deps/spdlog/src/*.cpp"]),
        hdrs = native.glob([
            "deps/fmt/include/**/*.h",
            "deps/spdlog/include/**/*.h",
        ]),
        copts = _COMMON_COPTS + ["-DSPDLOG_COMPILED_LIB"],
        cxxopts = _COMMON_CXXOPTS,
        includes = _COMMON_INCLUDES,
        visibility = ["//visibility:private"],
    )

    cc_library(
        name = "mscgen",
        srcs = native.glob(["deps/libmscgen/*.c"]) + [
            ":generated/mscgen_language.cpp",
            ":generated/mscgen_lexer.cpp",
        ],
        hdrs = native.glob(["deps/libmscgen/*.h"]) + [":generated/mscgen_lexer.l.h"],
        copts = _COMMON_COPTS,
        cxxopts = _COMMON_CXXOPTS,
        includes = _COMMON_INCLUDES,
        deps = [":lodepng"],
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = "xml",
        srcs = [":generated/xml.cpp"],
        hdrs = native.glob(["libxml/*.h"]) + [":generated/xml.l.h"],
        copts = _COMMON_COPTS,
        cxxopts = _COMMON_CXXOPTS,
        includes = _COMMON_INCLUDES,
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = "vhdlparser",
        srcs = native.glob([
            "vhdlparser/*.cc",
        ], exclude = [
            "vhdlparser/VhdlParser.cc",
            "vhdlparser/VhdlParserTokenManager.cc",
        ]) + [
            ":generated/VhdlParser_adj.cc",
            ":generated/VhdlParserTokenManager_adj.cc",
        ],
        hdrs = native.glob(["src/*.h", "vhdlparser/*.h", "vhdlparser/*.hpp"]),
        copts = _COMMON_COPTS,
        cxxopts = _COMMON_CXXOPTS,
        includes = _COMMON_INCLUDES,
        deps = [":doxygen_headers"],
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = "doxygen_version",
        srcs = [
            ":generated/doxyversion.cpp",
            ":generated/gitversion.cpp",
            "libversion/fullversion.cpp",
        ],
        hdrs = ["libversion/version.h"],
        copts = _COMMON_COPTS,
        cxxopts = _COMMON_CXXOPTS,
        includes = _COMMON_INCLUDES,
        visibility = ["//visibility:private"],
    )

    generated_headers = [
        ":generated/configvalues.h",
        ":generated/settings.h",
    ] + [
        _generated_label("%s.l.h" % lexer)
        for lexer in _LEXERS
    ] + [
        ":generated/ce_parse.hpp",
        ":generated/mscgen_lexer.l.h",
        ":generated/xml.l.h",
    ]

    cc_library(
        name = "doxygen_headers",
        hdrs = generated_headers + native.glob([
            "deps/TinyDeflate/*.hh",
            "deps/filesystem/*.hpp",
            "libversion/version.h",
            "src/*.h",
        ]),
        includes = _COMMON_INCLUDES,
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = "doxycfg",
        srcs = [
            ":generated/configimpl.cpp",
            ":generated/configoptions.cpp",
            ":generated/configvalues.cpp",
            "src/debug.cpp",
            "src/message.cpp",
            "src/portable.cpp",
            "src/portable_c.c",
            "src/trace.cpp",
        ],
        hdrs = native.glob(["src/*.h"]),
        copts = _COMMON_COPTS,
        cxxopts = _COMMON_CXXOPTS,
        includes = _COMMON_INCLUDES,
        deps = [":doxygen_headers", ":md5", ":spdlog"],
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = "doxymain",
        srcs = [
            ":generated/resources.cpp",
            ":generated/ce_parse.cpp",
        ] + [
            _generated_label("%s.cpp" % lexer)
            for lexer in _LEXERS
            if lexer != "configimpl"
        ] + native.glob([
            "src/*.cpp",
        ], exclude = [
            "src/debug.cpp",
            "src/main.cpp",
            "src/message.cpp",
            "src/portable.cpp",
            "src/trace.cpp",
        ]),
        hdrs = native.glob(["src/*.h"]),
        copts = _COMMON_COPTS,
        cxxopts = _COMMON_CXXOPTS,
        includes = _COMMON_INCLUDES,
        deps = [
            ":doxygen_headers",
            ":lodepng",
            ":md5",
            ":mscgen",
            ":spdlog",
            ":sqlite3",
            ":doxycfg",
            ":vhdlparser",
            ":xml",
        ],
        visibility = ["//visibility:private"],
    )
    cc_binary(
        name = "doxygen",
        srcs = ["src/main.cpp"],
        copts = _COMMON_COPTS,
        cxxopts = _COMMON_CXXOPTS,
        includes = _COMMON_INCLUDES,
        linkopts = ["-lm", "-pthread"],
        deps = [
            ":doxycfg",
            ":doxymain",
            ":doxygen_version",
            ":lodepng",
            ":md5",
            ":mscgen",
            ":sqlite3",
            ":vhdlparser",
            ":xml",
        ],
        visibility = ["//visibility:public"],
    )
