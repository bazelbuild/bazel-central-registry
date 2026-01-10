load("//contrib/bazel:defs.bzl", "GIT_COPTS")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "simple-ipc",
    srcs = [
        "ipc-shared.c",
    ] + select({
        "@platforms//os:windows": ["ipc-win32.c"],
        "//conditions:default": ["ipc-unix-socket.c"],
    }),
    copts = GIT_COPTS,
    deps = [
        "//:abspath",
        "//:gettext",
        "//:git_compat_util",
        "//:pkt_line",
        "//:simple_ipc",
        "//:strbuf",
        "//:thread_utils",
        "//:trace",
        "//:trace2",
    ] + select({
        "@platforms//os:windows": [],
        "//conditions:default": [
            "//:unix_socket",
            "//:unix_stream_server",
        ],
    }),
)
