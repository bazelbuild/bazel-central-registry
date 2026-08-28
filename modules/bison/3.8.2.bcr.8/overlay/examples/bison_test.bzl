"""Macro for end-to-end bison integration tests."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")
load("//:bison.bzl", "bison")

def bison_test(
        *,
        name,
        src,
        header = None,
        copts = [],
        linkopts = [],
        deps = [],
        **kwargs):
    """Runs bison on a .y grammar, compiles the generated C, and runs it as a cc_test.

    Creates two targets:
      - `<name>_gen`: invokes bison to produce C source (and optionally a header)
        from the grammar.
      - `<name>`: a cc_test that compiles and executes the generated code.

    The .y file must contain an embedded main() and lexer so the generated C is
    self-contained. Grammars that accept empty input (e.g. `input: %empty`)
    will exit 0 when cc_test provides no stdin.

    Args:
        name: Name of the cc_test target.
        src: Label of the .y grammar file to process.
        header: Filename for the generated header (e.g. "calc.h"). Must match
            the grammar's %define api.header.include value. If None, no header
            is generated.
        copts: Additional C compiler options for the generated code.
        linkopts: Additional linker options (e.g. ["-lm"] for math).
        deps: Additional cc_library deps for the generated code.
        **kwargs: Forwarded to cc_test.
    """
    outs = [name + ".c"]
    args = []
    if header:
        outs.append(header)
        args.append("--header=$(execpath " + header + ")")
    args.extend(["-o", "$(execpath " + name + ".c)", "$(execpath " + src + ")"])

    bison(
        name = name + "_gen",
        srcs = [src],
        outs = outs,
        args = args,
        testonly = True,
    )

    cc_test(
        name = name,
        srcs = [":" + name + "_gen"],
        copts = copts,
        linkopts = linkopts,
        deps = deps,
        **kwargs
    )
