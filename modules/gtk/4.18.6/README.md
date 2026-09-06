# GTK 4.18.6

Native `cc_library` build for little-endian Linux x86-64 and AArch64, with
X11, Cairo, OpenGL, printing, and AT-SPI support. Wayland, Vulkan, Broadway,
Windows, and macOS backends are not enabled. Link `@gtk` from C/C++ or wire
it to gtk-rs `-sys` crates with their Cargo build scripts disabled.

The source/header lists follow `gdk/meson.build`, `gsk/meson.build`, and
`gtk/meson.build`. When updating, reconcile those lists, platform exclusions,
configuration macros, and generated resources with the new upstream release.
The upstream Python and GLib generators run on the execution platform;
GTK sources compile with the target C/C++ toolchain. Built-in resources are
compiled into the archive. Theme, locale, font, and display-server data remain
runtime dependencies. OpenGL drivers are loaded at runtime by libepoxy.

The native dependency closure uses BCR modules. Use C++17 or newer for the
transitive HarfBuzz/ICU dependency (for example `--cxxopt=-std=c++17`).
The default build supports raster images. For built-in SVG loading, also link
`@librsvg` and `@librsvg//:pixbuf_loader` and set
`--@gdk-pixbuf//:builtin_svg`. See librsvg's README for Rust consumers.

The smoke test exercises public GTK/GDK APIs without requiring a display.
