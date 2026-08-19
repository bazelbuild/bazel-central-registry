"""Generate a header that includes a set of other headers.
This creates a rule to generate a header that includes a list of other headers.
The generated file will be of the form:
    #include "path/to/hdr"
    #include "path/to/hdr"
Args:
    hdrs (:obj:`str`): List of files or file labels of headers that the
        generated header will include.
"""

# Generate a header that includes a set of other headers
def _generate_include_header_impl(ctx):
    # Collect list of headers
    hdrs = []
    for h in ctx.attr.hdrs:
        for f in h.files.to_list():
            hdr = f.short_path
            hdrs.append(hdr)

    # Generate include header
    content = "// Generated headers\n"
    content = content + "\n".join(["#include \"%s\"" % h for h in hdrs])
    ctx.actions.write(output = ctx.outputs.out, content = content)

generate_include_header = rule(
    attrs = {
        "hdrs": attr.label_list(allow_files = True),
        "out": attr.output(mandatory = True),
    },
    implementation = _generate_include_header_impl,
)
