# Pango 1.52.1

Bazel-native Linux build of upstream Pango 1.52.1, licensed LGPL-2.1-or-later.
The release's `COPYING` file and copyright notices are retained.

## Targets

Add `bazel_dep(name = "pango", version = "1.52.1")` to `MODULE.bazel`.

| Target | Purpose / output |
| --- | --- |
| `@pango` or `@pango//:pango` | Core `cc_library`; include `<pango/pango.h>` |
| `@pango//:pangoft2` | FreeType/fontconfig `cc_library` |
| `@pango//:pangocairo` | Cairo `cc_library` |
| `@pango//:pango_shared` | `libpango-1.0.so.0` |
| `@pango//:pangoft2_shared` | `libpangoft2-1.0.so.0` |
| `@pango//:pangocairo_shared` | `libpangocairo-1.0.so.0` |

C/C++ consumers can link the `cc_library` targets statically or use the explicit
shared targets through `cc_shared_library.dynamic_deps`. The explicit shared
libraries own dependency implementations once: core Pango contains the common
text stack; FT2 depends dynamically on core; PangoCairo depends on both and
contains Cairo/Pixman. FFI consumers using GLib/GObject or fontconfig APIs should
resolve those functions from `pango_shared` to keep objects in the same native
stack. Standard C/C++ runtime libraries come from the execution platform.

## Loading from runfiles

For a Python binary, pass a runfiles path and declare the shared target as data:

```starlark
args = ["$(rlocationpath @pango//:pangocairo_shared)"],
data = ["@pango//:pangocairo_shared"],
deps = ["@rules_python//python/runfiles"],
```

```python
import ctypes
import os
import sys
from python.runfiles import runfiles

library_path = runfiles.Create().Rlocation(sys.argv[1])
library = ctypes.CDLL(library_path, mode=os.RTLD_NOW | os.RTLD_LOCAL)
```

The same resolved path works with `ffi.dlopen`. Bazel supplies transitive shared
library runfiles. Use `rlocationpath` rather than hard-coding repository names.
When materializing runfiles, preserve file identity (for example, `cp -aL`),
or copy the three `.so.0` files together into one directory. SONAMEs and `$ORIGIN`
search paths support that layout. Avoid loading separate copies through both a
canonical path and a `_solib` alias. No host Pango or `LD_LIBRARY_PATH` is needed.

## Fonts and Thai dictionaries

Consumers supply font files and fontconfig configuration as runtime inputs.
For hermetic rendering, package them in runfiles and initialize an explicit
fontconfig configuration. The test module demonstrates `FcConfigAppFontAddFile`
and `pango_fc_font_map_set_config` with bundled fonts and no host font discovery.

Thai word breaking uses libthai's embedded dictionary by default, including
after relocation. To override it, add `@libthai//:dictionary` to `data`, resolve
its runfiles path, and set `LIBTHAI_DICTDIR` to the parent directory before the
first layout call. This requires a direct `libthai` dependency. An unusable
override falls back to the embedded dictionary.

This initial port supports Linux with the FreeType/fontconfig and Cairo
backends. Xft, native macOS/Windows backends, and introspection are not included.
