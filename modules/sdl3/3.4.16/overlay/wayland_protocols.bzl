"""Client code for the XML files of the Wayland protocols.

SDL supplies these files in wayland-protocols/ and loads libwayland-client at
runtime, so Bazel compiles the protocol tables into SDL itself, as SDL's CMake
build does.

The genrules write the headers at the package root. SDL includes them with
quotes, and Bazel searches the output directory of the package first, so SDL's
own wayland-client-protocol.h has priority over the header that the wayland
module exports.
"""

# The Wayland backend is Linux-only; this also keeps `...` from building the
# scanner elsewhere.
_LINUX_ONLY = ["@platforms//os:linux"]

def wayland_protocol_sources(xmls):
    """This function declares the wayland-scanner genrules for `xmls`.

    Returns a struct with `srcs` (the generated *-protocol.c files) and `hdrs`
    (the generated *-client-protocol.h files).
    """
    srcs = []
    hdrs = []
    for xml in xmls:
        protocol = xml.removeprefix("wayland-protocols/").removesuffix(".xml")
        src = "%s-protocol.c" % protocol
        hdr = "%s-client-protocol.h" % protocol
        native.genrule(
            name = "%s_wayland_protocol_source" % protocol,
            srcs = [xml],
            outs = [src],
            cmd = "$(location @wayland//:wayland_scanner) private-code < $(location %s) > $@" % xml,
            tools = ["@wayland//:wayland_scanner"],
            target_compatible_with = _LINUX_ONLY,
        )
        native.genrule(
            name = "%s_wayland_protocol_header" % protocol,
            srcs = [xml],
            outs = [hdr],
            cmd = "$(location @wayland//:wayland_scanner) client-header < $(location %s) > $@" % xml,
            tools = ["@wayland//:wayland_scanner"],
            target_compatible_with = _LINUX_ONLY,
        )
        srcs.append(src)
        hdrs.append(hdr)
    return struct(srcs = srcs, hdrs = hdrs)
