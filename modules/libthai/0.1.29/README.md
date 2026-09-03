# libthai 0.1.29

Bazel-native Linux targets for the upstream release:

- `@libthai//:libthai`: public C/C++ library (`<thai/thbrk.h>`).
- `@libthai//:dictionary`: the generated `thbrk.tri` runtime file.

Bazel builds libdatrie's upstream `trietool` for the execution platform and
compiles the upstream word lists in deterministic `LC_ALL=C` sorted order,
following `data/Makefile.am`. No configure or pkg-config step runs.

The library includes the dictionary as runtime data. Resolve
`$(rlocationpath @libthai//:dictionary)` with the consumer's runfiles library.
Pass the resulting filename to `th_brk_new(filename)`, or set
`LIBTHAI_DICTDIR` to its parent directory before any default word-breaker
calls (including Pango calls). There is no fallback to `/usr/share/libthai`:
the compiled fallback is `/nonexistent/libthai`.

The test module runs six upstream character/input/rendering tests and a
consumer test checking explicit and environment-based dictionary loading,
known Thai word boundaries, and failure when no dictionary is supplied.
The module advertises Linux support; other platforms are not validated.
