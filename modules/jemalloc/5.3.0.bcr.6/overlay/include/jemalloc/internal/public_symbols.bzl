"Reproduce configure.ac's public_syms and wrap_syms, its public_symbols.txt generation and the headers generated from it"

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

_GENERATOR = attr.label(
    default = Label("//tools/generators:public_symbols_gen"),
    cfg = "exec",
    executable = True,
)

def _symbol_list_impl(ctx):
    output = ctx.actions.declare_file(ctx.attr.out)
    headers = {}
    for header in ctx.files.headers:
        if header.basename in headers:
            fail("headers holds two files named {}".format(header.basename))
        headers[header.basename] = header

    args = ctx.actions.args()
    args.add_all(["list", output])
    args.add_all(ctx.attr.symbols, format_each = "--symbol=%s")
    for symbol, coupling in ctx.attr.optional_symbols.items():
        if len(coupling) != 2:
            fail("optional_symbols[{}] must be [header, macro], got {}".format(symbol, coupling))
        header, macro = coupling
        if header not in headers:
            fail("optional_symbols[{}] names {}, which is not among headers {}".format(symbol, header, sorted(headers)))
        args.add("--symbol={}:{}:{}".format(symbol, macro, headers[header].path))

    ctx.actions.run(
        executable = ctx.executable._generator,
        arguments = [args],
        inputs = ctx.files.headers,
        outputs = [output],
        mnemonic = "SymbolList",
    )
    return [DefaultInfo(files = depset([output]))]

symbol_list = rule(
    doc = "Writes configure.ac's public_syms or wrap_syms, one symbol per line: `symbols`, then each optional symbol " +
          "whose macro its configured header defines. configure.ac appends an optional symbol in the branch where it " +
          "defines that macro, so the list follows the probes exactly.",
    implementation = _symbol_list_impl,
    attrs = {
        "headers": attr.label_list(
            doc = "The configured headers that optional_symbols name by basename.",
            allow_files = [".h"],
        ),
        "optional_symbols": attr.string_list_dict(
            doc = "Each optional symbol, in configure.ac's order, mapped to [header basename, macro].",
        ),
        "out": attr.string(
            doc = "Name of the generated file",
            mandatory = True,
        ),
        "symbols": attr.string_list(doc = "The symbols listed unconditionally, in configure.ac's order."),
        "_generator": _GENERATOR,
    },
)

def _public_symbols_impl(ctx):
    output = ctx.actions.declare_file(ctx.attr.out)
    args = ctx.actions.args()
    args.add_all(["txt", output, ctx.file.symbols])
    args.add(ctx.attr._prefix[BuildSettingInfo].value, format = "--prefix=%s")
    args.add(ctx.attr.mangling_map, format = "--mangling-map=%s")
    ctx.actions.run(
        executable = ctx.executable._generator,
        arguments = [args],
        inputs = [ctx.file.symbols],
        outputs = [output],
        mnemonic = "PublicSymbols",
    )
    return [DefaultInfo(files = depset([output]))]

public_symbols = rule(
    doc = "Writes public_symbols.txt as configure.ac's AC_CONFIG_COMMANDS does, from the public_syms `symbols`.",
    implementation = _public_symbols_impl,
    attrs = {
        "mangling_map": attr.string(
            doc = "The equivalent of --with-mangling=<key_1>:<value_1>,<key_2>:<value_2>,...",
        ),
        "out": attr.string(
            doc = "Name of the generated file",
            mandatory = True,
        ),
        "symbols": attr.label(
            doc = "configure.ac's public_syms, as a symbol_list writes it",
            allow_single_file = True,
            mandatory = True,
        ),
        "_generator": _GENERATOR,
        "_prefix": attr.label(default = "//settings/flags:jemalloc_prefix_resolved"),
    },
)

_SCRIPTS = [
    "jemalloc_mangle.sh",
    "jemalloc_rename.sh",
    "public_namespace.sh",
    "public_unnamespace.sh",
]

def _public_symbols_header_impl(ctx):
    output = ctx.actions.declare_file(ctx.attr.out)
    args = ctx.actions.args()
    args.add_all([ctx.attr.script, output, ctx.file.public_symbols])
    args.add(ctx.attr.symbol_prefix, format = "--symbol-prefix=%s")
    ctx.actions.run(
        executable = ctx.executable._generator,
        arguments = [args],
        inputs = [ctx.file.public_symbols],
        outputs = [output],
        mnemonic = "PublicSymbolsHeader",
    )
    return [DefaultInfo(files = depset([output]))]

public_symbols_header = rule(
    doc = "Writes what the upstream `script` prints when given `public_symbols`.",
    implementation = _public_symbols_header_impl,
    attrs = {
        "out": attr.string(mandatory = True),
        "public_symbols": attr.label(
            doc = "public_symbols.txt, as a public_symbols target writes it",
            allow_single_file = True,
            mandatory = True,
        ),
        "script": attr.string(mandatory = True, values = _SCRIPTS),
        "symbol_prefix": attr.string(doc = "The second argument of jemalloc_mangle.sh."),
        "_generator": _GENERATOR,
    },
)
