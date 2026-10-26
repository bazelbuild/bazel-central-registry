# librsvg 2.61.4

`@librsvg` exposes librsvg's C headers and a Rust static library. Native
libraries come from BCR; the gtk-rs sys-crate build scripts are disabled.
Bazel targets generate sRGB lookup tables and version constants.
Linux x86-64 and AArch64 are supported; use C++17 or newer.

`@librsvg//:pixbuf_loader` is the upstream GdkPixbuf C adapter with static
registration symbols. Link it alongside `@librsvg` and build with
`--@gdk-pixbuf//:builtin_svg` to decode SVG through GdkPixbuf without loading
a shared plugin. The test decodes an SVG and checks dimensions and pixel color.
The flag is off by default, so GdkPixbuf users do not acquire a Rust dependency.

Rust applications that already depend on `librsvg-c` should link the renderer
through Cargo once, plus `@librsvg//:headers` and `@librsvg//:pixbuf_loader`.
Do not also link `@librsvg` into those applications. The module's
`crate.annotation` entries show how to wire gtk-rs sys crates to native BCR
libraries.

`rules_rs` reads the release archive's unmodified `Cargo.toml` and `Cargo.lock`.
The `rsvg` and `librsvg-c` Bazel targets compile the upstream workspace crates
directly, using the Rust dependency versions recorded by upstream.

`//rsvg:srgb_generator` compiles upstream's unmodified `rsvg/build.rs` as a
Rust binary with `--cfg=docsrs` to disable system-library probing.
`//rsvg:srgb_tables` runs that binary to produce `srgb-codegen.rs`.
`//:rust_version` generates `version.rs` from a template using the same version
values as the C header. Both files are declared compilation inputs; the source
patch supplies their locations to Rust's `include!` expressions. The `rsvg`
and `librsvg-c` targets do not use `cargo_build_script`.

System libc and compiler runtimes are still needed by the final executable.
