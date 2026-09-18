# libthai 0.1.29

Bazel-native Linux targets for the upstream release:

- `@libthai//:thai`: public C/C++ library (`<thai/thbrk.h>`).
- `@libthai//:libthai`: alias, also available as `@libthai`.
- `@libthai//:dictionary`: the generated `thbrk.tri` file for explicit loading.

Bazel builds libdatrie's upstream `trietool` for the execution platform and
compiles the upstream word lists in deterministic `LC_ALL=C` sorted order,
following `data/Makefile.am`. No configure or pkg-config step runs.

The library embeds that generated dictionary. The default `th_brk_new(NULL)`
and `th_brk` APIs work without resolving runfiles or setting environment
variables, including when a shared library or executable is relocated. A small
patch reads the embedded data through `fmemopen` and libdatrie's `trie_fread`.
It never searches a host-installed dictionary directory.

Explicit `th_brk_new(filename)` calls retain upstream behavior, including
failure for invalid paths. `LIBTHAI_DICTDIR` remains an override for the default
API; if its dictionary cannot be loaded, the embedded dictionary is used.
Consumers that need the standalone dictionary can put `:dictionary` in `data`
and resolve its `$(rlocationpath @libthai//:dictionary)` with their runfiles API.

Tests cover six upstream character/input/rendering APIs, dictionary loading
from runfiles, and the default word breaker with static and dynamic linking.
The module advertises Linux support; other platforms are not validated.

License: `LGPL-2.1-or-later`; see `COPYING` in the upstream source archive.
