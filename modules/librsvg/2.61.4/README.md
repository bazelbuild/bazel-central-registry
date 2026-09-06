# librsvg 2.61.4

`@librsvg` exposes librsvg's C headers and a Rust static library. Native
libraries come from BCR; the gtk-rs sys-crate build scripts are disabled.
The upstream build scripts still generate sRGB lookup tables and version
constants. Linux x86-64 and AArch64 are supported; use C++17 or newer.

`@librsvg//:pixbuf_loader` is the upstream GdkPixbuf C adapter with static
registration symbols. Link it alongside `@librsvg` and build with
`--@gdk-pixbuf//:builtin_svg` to decode SVG through GdkPixbuf without loading
a shared plugin. The test decodes an SVG and checks dimensions and pixel color.
The flag is off by default, so GdkPixbuf users do not acquire a Rust dependency.

Rust applications that already depend on `librsvg-c` should link the renderer
through Cargo once, plus `@librsvg//:headers` and `@librsvg//:pixbuf_loader`.
Do not also link `@librsvg` into those applications. The module's
`crate.annotation` entries show how to wire gtk-rs sys crates to native BCR
libraries. The two exported `bazel/librsvg_bazel_*.patch` files adapt the pinned
2.61.4 Git revision's build scripts; the C adapter is from the matching release.
The version generator uses the pinned Cargo package version, avoiding paths
back into the release archive.

The small Cargo workspace pins the renderer and its Rust dependencies using
rules_rs; it does not invoke Cargo to compile or probe system libraries.
System libc and compiler runtimes are still needed by the final executable.
