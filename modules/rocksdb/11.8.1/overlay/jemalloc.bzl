"""Keep Darwin jemalloc separate from the system allocator."""

load("@with_cfg.bzl", "with_cfg")

darwin_jemalloc, _darwin_jemalloc_internal = with_cfg(
    native.alias,
).set(
    Label("@jemalloc//settings/flags:jemalloc_prefix"),
    "_rjem_",
).set(
    Label("@jemalloc//settings/flags:enable_zone_allocator"),
    "no",
).build()
