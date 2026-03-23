# xkbcommon

BCR packaging summary for libxkbcommon.

Public targets:

- `@xkbcommon`
- `@xkbcommon//:xkbcommon_headers`

Packaging notes:

- This initial BCR package only exposes the core `libxkbcommon` library.
- `config.h` is generated from a checked-in template with fixed upstream-style defaults plus a small set of libc/toolchain probes from `rules_cc_autoconf`.
- `src/xkbcomp/parser.y` is generated with `rules_bison`.
- The module also pins `rules_m4` to a Bazel 9-compatible version because `rules_bison` pulls it transitively.
- Internal `src/**/*.h` headers and generated headers are kept private to the implementation.
- The packaged library sources are multi-license permissive code (`MIT`, `MIT-open-group`, `HPND`, `HPND-sell-variant`, and `DEC-3-Clause`) as documented by the upstream consolidated `LICENSE` file exported by this package.

Limitations:

- `xkbcommon-x11` is not packaged in this version.
- `xkbregistry` is not packaged in this version.
- CLI tools and Wayland helpers are not packaged in this version.
- Runtime keymap and locale discovery still depends on host XKB and X locale data paths when those code paths are used.
- The generated `config.h` is intentionally smaller than upstream Meson's full configuration surface.

Presubmit:

- Builds and tests `@xkbcommon//:xkbcommon_headers_consumer_compile_test`, `@xkbcommon//:xkbcommon_consumer_link_test`, and `@xkbcommon//:xkbcommon_compose_from_buffer_test`.
- The header compile test covers the full exported public header surface.
- The compose smoke test is hermetic and uses an in-memory compose table instead of host locale/X11 data.
