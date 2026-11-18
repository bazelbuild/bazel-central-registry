"""Generate a cc_library for the client side of a Wayland protocol.

    load("@wayland-protocols//:wayland_protocol.bzl", "wayland_client_protocol")

    wayland_client_protocol(
        name = "xdg_shell",
        src = "@wayland-protocols//:stable/xdg-shell/xdg-shell.xml",
    )

produces `xdg-shell-client-protocol.h` (include it by that bare name, e.g.
`#include <xdg-shell-client-protocol.h>`) and the matching glue code, linked
against @wayland//:wayland_client. Only the generated header is exported (via
strip_include_prefix), so the generated .c file and the directory holding it
never land on a consumer's include path. Set
`basename` to change the generated file names, e.g. basename =
"wayland-xdg-shell" gives `wayland-xdg-shell-client-protocol.h` (the
spelling ECM's ecm_add_wayland_client_protocol uses).

wayland-scanner is run directly (no shell), so this also works when the
execution platform is Windows.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

def _wayland_scanner_impl(ctx):
    outputs = []
    # public-code, not private-code: private-code gives the interface symbols
    # hidden visibility, which breaks as soon as the generated library and its
    # user end up in different shared objects (e.g. Bazel's dynamically linked
    # tests).
    for mode, out in [("client-header", ctx.outputs.header), ("public-code", ctx.outputs.code)]:
        ctx.actions.run(
            executable = ctx.executable._scanner,
            arguments = [mode, ctx.file.src.path, out.path],
            inputs = [ctx.file.src],
            outputs = [out],
            mnemonic = "WaylandScanner",
            progress_message = "Generating %s (%s)" % (out.short_path, mode),
        )
        outputs.append(out)
    return [DefaultInfo(files = depset(outputs))]

_wayland_scanner = rule(
    implementation = _wayland_scanner_impl,
    attrs = {
        "code": attr.output(mandatory = True),
        "header": attr.output(mandatory = True),
        "src": attr.label(allow_single_file = [".xml"], mandatory = True),
        "_scanner": attr.label(
            default = Label("@wayland//:wayland_scanner"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def wayland_client_protocol(name, src, basename = None, header = None, **kwargs):
    """cc_library with the client header and glue code for one protocol.

    Args:
      name: target name.
      src: the protocol XML file (a label string).
      basename: generated file prefix; defaults to the XML file name.
      header: generated header file name, overriding
        "<basename>-client-protocol.h" (some projects expect e.g.
        "xdg-foreign-unstable-v2.h").
      **kwargs: forwarded to cc_library (visibility, target_compatible_with, ...).
    """
    if basename == None:
        # The file name without directories or extension, e.g. "xdg-shell".
        basename = src.split(":")[-1].split("/")[-1].removesuffix(".xml")
    gen_dir = "_wl_" + name
    if header == None:
        header = basename + "-client-protocol.h"
    header = "%s/%s" % (gen_dir, header)
    code = "%s/%s-protocol.c" % (gen_dir, basename)
    _wayland_scanner(
        name = name + "_gen",
        src = src,
        header = header,
        code = code,
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = name,
        srcs = [code],
        hdrs = [header],
        strip_include_prefix = gen_dir,
        deps = [Label("@wayland//:wayland_client")],
        **kwargs
    )
