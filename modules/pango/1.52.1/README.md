# Pango 1.52.1

This module builds the **upstream Pango 1.52.1 release**. The archive SHA-256 is
`58728a0a2d86f60761208df9493033d18ecb2497abac80ee1a274ad0c6e55f0f`.
The project license is LGPL-2.1-or-later; the release's `COPYING` file and
upstream copyright notices are retained.

## Targets

| Target | Purpose / output |
| --- | --- |
| `@pango//:pango` (or `@pango`) | Core `cc_library`, including `<pango/pango.h>` |
| `@pango//:pangoft2` | FreeType/fontconfig `cc_library` |
| `@pango//:pangocairo` | Cairo `cc_library` |
| `@pango//:pango_shared` | `libpango-1.0.so.0` |
| `@pango//:pangoft2_shared` | `libpangoft2-1.0.so.0` |
| `@pango//:pangocairo_shared` | `libpangocairo-1.0.so.0` |

Add `bazel_dep(name = "pango", version = "1.52.1")` to `MODULE.bazel`.
C/C++ consumers can depend on the `cc_library` targets using normal static
linkage (`linkstatic = True` on binaries/tests). They can also use the shared
targets through `cc_shared_library.dynamic_deps`. The explicit shared targets
avoid relying on automatically generated shared variants of dependency
`cc_library` targets, which are not all usable independently (notably Pixman).

The three explicit shared targets form one runtime stack. GLib/GObject,
HarfBuzz, FreeType, fontconfig, FriBidi, libpng, libthai, libdatrie, and zlib
are linked into the core Pango shared library once. FT2 depends dynamically on core Pango; PangoCairo
depends dynamically on both. This avoids duplicate GType registries and
other dependency globals when all three libraries are loaded with `RTLD_LOCAL`.
Cairo and Pixman are included in PangoCairo. Standard compiler/C/C++ runtime
libraries still come from the selected toolchain and execution platform.
FFI consumers that also call GLib/GObject or fontconfig APIs should resolve
those functions from `pango_shared`, keeping objects within this same native
stack rather than passing them to a separately loaded copy of a dependency.

## Loading from Python runfiles

Use these targets as `data` and pass paths through `$(rlocationpath ...)`.
Do not hard-code Bzlmod canonical repository names such as `pango+` or `pango~`.
For example, a `py_binary` can specify:

```starlark
args = ["$(rlocationpath @pango//:pangocairo_shared)"],
data = ["@pango//:pangocairo_shared"],
deps = ["@rules_python//python/runfiles"],
```

Its Python code can load the resolved path with `ctypes.CDLL`, or pass the same
path to `ffi.dlopen`:

```python
import ctypes
import os
import sys
from python.runfiles import runfiles

library_path = runfiles.Create().Rlocation(sys.argv[1])
library = ctypes.CDLL(library_path, mode=os.RTLD_NOW | os.RTLD_LOCAL)
```

Bazel supplies the transitive shared-library runfiles. Preserve file identity
when materializing that tree (for example, `cp -aL`, which preserves hardlinks),
or copy the three `.so.0` files together into one otherwise empty directory.
Explicit SONAMEs and an `$ORIGIN` search path support the latter layout.
Avoid creating separate copies of a DSO at both its canonical path and a
`_solib` alias and then loading both copies by absolute path. No `LD_LIBRARY_PATH`, host Pango, or host `pkg-config` is needed.

## Fonts

Font files and fontconfig rules are runtime inputs chosen by the consumer.
For hermetic rendering, provide those files through runfiles and initialize
an explicit fontconfig configuration. The test module demonstrates
`FcConfigAppFontAddFile` and `pango_fc_font_map_set_config` with bundled fonts;
it disables host fontconfig discovery. Loading the shared libraries alone
does not select or package application fonts.

## Thai dictionary data

Dictionary-based Thai word breaking works by default. Libthai embeds the
Bazel-generated dictionary from its upstream word lists in the library, so
Pango needs no dictionary runfile or environment variable, including when the
three shared libraries are relocated together.

Consumers can still select a dictionary explicitly. Add
`bazel_dep(name = "libthai", version = "0.1.29")` and
`@libthai//:dictionary` to `data`, resolve its runfiles path, and set
`LIBTHAI_DICTDIR` to the file's parent directory before the first Pango layout
or word-break call. Libthai gives that override precedence and falls back to
its embedded dictionary if the directory has no usable dictionary. No host
`/usr/share/libthai` lookup is needed.

## Overlay maintenance and scope

`overlay/BUILD.bazel` transcribes the source and installed-header lists from
upstream `pango/meson.build`. GLib's Bazel `mkenums` rule generates the enum
registration code from upstream templates. `expand_template` generates the
version header. The release already contains the Unicode tables and emoji
scanner; the script-specific `break-*.c` files and scanner are textual inputs,
not standalone translation units. `config.h` fixes the selected feature set
against the pinned BCR dependencies; no configure or host feature detection
runs. Public include paths use virtual headers to avoid dependency `config.h`
collisions. Pango sources themselves are unpatched.

This initial port supports Linux. The presubmit matrix declares Debian 13 and
Ubuntu 24.04, with Bazel 7.x, 8.x, and 9.x. Actual local results are recorded in
`VALIDATION.md`; other OS backends are explicitly incompatible.

Dependency details:

- `cairo@1.18.4` has no FreeType/fontconfig font backend. The accompanying
  additive `cairo@1.18.4.bcr.1` revision enables upstream's three backend
  sources and feature macros without changing Cairo's upstream version.
  It also enables upstream's Pixman glyph cache, preserving fractional glyph
  positions instead of rounding them to whole pixels.
  That revision must be registered before Pango can be submitted alone.
- `harfbuzz@14.1.0` separates `hb-unicode.cc` and its GLib implementation
  across archives in a way that breaks some static links. Pango's Linux
  link flags force `hb_glib_get_unicode_funcs` into the link. The smallest
  future cleanup is a HarfBuzz BCR revision that fixes this archive layout,
  after which this workaround can be removed.

The accompanying `freetype@2.14.1.bcr.1` revision enables PNG-backed color
bitmap glyphs through the existing BCR libpng dependency. The new
`libdatrie@0.2.13` and `libthai@0.1.29` modules supply the Thai backend and
embedded dictionary. Register these dependency revisions before submitting
Pango alone. Xft, macOS/Windows font backends, and introspection are outside
this Linux port's scope.

## Validation commands

From the BCR checkout:

```sh
bazel run //tools:update_integrity -- pango --version=1.52.1
bazel run //tools:bcr_validation -- --check=pango@1.52.1
bazel run //tools:bcr_validation -- --check=cairo@1.18.4.bcr.1
bazel run //tools:setup_presubmit_repos -- --module pango@1.52.1
```

Follow the helper's commands to build the anonymous consumer and run
`//:all` in the generated `bazel_test` module. The tests cover a C++ consumer,
independent `RTLD_NOW | RTLD_LOCAL` loading in all three initial-load orders,
shared GObject identity, relocation of the three DSOs together, FT2 layout,
Cairo rendering, PNG color emoji, dictionary-based Thai word boundaries,
and `/proc/self/maps` checks excluding host copies of the native stack.
