"""Utility Bazel rules for OpenCV."""

def _blob2hdr_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)

    ctx.actions.run(
        executable = ctx.executable._blob2hdr_tool,
        inputs = [ctx.file.src],
        outputs = [out],
        arguments = [ctx.file.src.path, out.path, ctx.attr.cpp_variable],
        mnemonic = "Blob2Hdr",
        progress_message = "Generating %s from %s" % (ctx.attr.out, ctx.file.src.basename),
    )

    return [DefaultInfo(files = depset([out]))]

_blob2hdr = rule(
    implementation = _blob2hdr_impl,
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "Binary input file to embed.",
        ),
        "out": attr.string(
            mandatory = True,
            doc = "Name of the generated header file.",
        ),
        "cpp_variable": attr.string(
            mandatory = True,
            doc = "Name of the C++ static array variable in the generated header.",
        ),
        "_blob2hdr_tool": attr.label(
            default = Label("//:blob2hdr"),
            executable = True,
            cfg = "exec",
            doc = "The blob2hdr conversion tool (py_binary, exec configuration).",
        ),
    },
)

def blob2hdr(name, src, out, cpp_variable, **kwargs):
    """Converts a binary blob into a C header declaring a static unsigned char array.

    Equivalent to the CMake ocv_blob2hdr() function. Reads a binary file and
    generates a C header containing its contents as a static const unsigned char
    array, with 16 bytes per line.

    The generated header has the form:

        // Auto generated file.
        static const unsigned char <cpp_variable>[] =
        {
        0xNN, 0xNN, ..., 0xNN,
        ...
        0xNN, 0xNN, ..., 0xNN
        };

    Args:
        name: The Bazel rule name.
        src: The binary input file (label).
        out: Filename for the generated header.
        cpp_variable: Name of the C++ array variable in the header.
        **kwargs: Additional arguments forwarded to the underlying rule
                  (e.g. visibility, compatible_with).
    """
    _blob2hdr(
        name = name,
        src = src,
        out = out,
        cpp_variable = cpp_variable,
        **kwargs
    )
