# Patches

## `windows-compat.patch`

Windows/MSVC compatibility fixes for GNU patch 2.8. Adds `#ifdef _WIN32`
guards around POSIX APIs unavailable on Windows:

- `backupfile.c`: replace `rewinddir()` with `closedir()`+reopen on Win32.
- `pch.c`: guard `S_IFLNK` `static_assert` (MSVC does not define `S_IFLNK`).
- `safe.c`/`safe.h`: stub `rlim_t`, skip `getrlimit()`, exclude `safe_lchown()`.
- `util.c`: skip `lchown`/`fchmod` code paths, guard `SIGHUP` and `SIGCHLD`.

These are portable `#ifdef` guards that could be upstreamed to GNU patch
if the project decides to officially support Windows/MSVC builds.

## `stdint-comment-fix.patch`

Prevents spurious autoconf substitution inside a C comment. The gnulib
`stdint.in.h` template mentions `@NEXT_STDINT_H@` inside a comment.
`rules_cc_autoconf` treats every `@...@` token as a substitution variable,
which corrupts the comment. Adding spaces (`@ NEXT_STDINT_H @`) stops the
pattern from matching while preserving the comment text.

Not upstreamable: this is a workaround specific to the Bazel
`rules_cc_autoconf` build.
