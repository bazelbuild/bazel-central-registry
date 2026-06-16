WAYLAND_PROTOCOL_NAMES = [
    "cursor-shape-v1",
    "fractional-scale-v1",
    "idle-inhibit-unstable-v1",
    "keyboard-shortcuts-inhibit-unstable-v1",
    "pointer-constraints-unstable-v1",
    "primary-selection-unstable-v1",
    "relative-pointer-unstable-v1",
    "tablet-unstable-v2",
    "text-input-unstable-v3",
    "viewporter",
    "xdg-activation-v1",
    "xdg-decoration-unstable-v1",
    "xdg-output-unstable-v1",
    "xdg-shell",
    "xdg-toplevel-icon-v1",
]

WAYLAND_PROTOCOL_SRCS = [
    "generated/wayland-protocols/%s-protocol.c" % protocol
    for protocol in WAYLAND_PROTOCOL_NAMES
]

WAYLAND_PROTOCOL_HDRS = [
    "generated/wayland-protocols/%s-client-protocol.h" % protocol
    for protocol in WAYLAND_PROTOCOL_NAMES
]

def declare_wayland_protocols():
    for protocol in WAYLAND_PROTOCOL_NAMES:
        native.genrule(
            name = "%s_wayland_protocol_source" % protocol,
            srcs = ["wayland-protocols/%s.xml" % protocol],
            outs = ["generated/wayland-protocols/%s-protocol.c" % protocol],
            cmd = "$(location @wayland//:wayland_scanner) private-code < $(location wayland-protocols/%s.xml) > $@" % protocol,
            tools = ["@wayland//:wayland_scanner"],
        )
        native.genrule(
            name = "%s_wayland_protocol_header" % protocol,
            srcs = ["wayland-protocols/%s.xml" % protocol],
            outs = ["generated/wayland-protocols/%s-client-protocol.h" % protocol],
            cmd = "$(location @wayland//:wayland_scanner) client-header < $(location wayland-protocols/%s.xml) > $@" % protocol,
            tools = ["@wayland//:wayland_scanner"],
        )
