# libdatrie 0.2.13

Bazel-native Linux targets for the upstream release:

- `@libdatrie//:libdatrie`: public C/C++ library (`<datrie/trie.h>`).
- `@libdatrie//:trietool`: upstream dictionary compiler, usable as a
  `genrule` tool so Bazel builds it for the execution platform.

The library needs only the C runtime. The tool uses Linux's C-runtime
`iconv` and `nl_langinfo`; its configuration is explicit, with no configure,
pkg-config, or host library discovery. No upstream source patch is needed.

The consumer test stores and retrieves a Thai key, round-trips the trie
through the public file API, and verifies deletion and independent copies.
The libthai consumer additionally exercises the tool on its full dictionary.
