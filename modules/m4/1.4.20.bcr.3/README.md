# Patches

This version ships the following patches on top of upstream GNU m4 1.4.20:

- **`windows-binary-mode.patch`** -- At the start of `output_init()` in `src/output.c`, call `SET_BINARY(STDOUT_FILENO)`
when `SET_BINARY` is defined. On Windows, the C runtime defaults text mode on stdout, which translates newlines to
CRLF. m4 must write its output in binary mode so generated files are not corrupted; this matches the usual MinGW/MSVC
pattern for binary-safe stdout.

- **`stdint-comment-subst.patch`** -- In `lib/stdint.in.h`, the comment that mentions the autoconf token `@NEXT_STDINT_H@`
is rewritten so the `@...@` sequence is split with spaces (`@ NEXT_STDINT_H @`). That keeps the comment readable but avoids
accidental processing of the token as a substitution placeholder by tooling that scans for `@NAME@` patterns during the
Bazel build.

- **`musl-libc-compat.patch`** -- Replaces `#error` directives in gnulib's `fpending.c` and `freadahead.c` with safe
`return 1` fallbacks, allowing m4 to compile on platforms with opaque `FILE` structs (e.g. musl libc) where these files
would otherwise fail to build. This mirrors the approach taken by rules\_m4 (see
[jmillikin/rules_m4@275873f](https://github.com/jmillikin/rules_m4/commit/275873f27e9aa74fcf6ea22a381cc63fbd487888)),
which stubs out these functions because musl provides `__fpending` and `__freadahead` natively and these gnulib
replacements should not be compiled in the first place.

- **`error-h-shadowing.patch`** -- Renames all `#include <error.h>` to `#include <m4-error.h>` across 14 source files
in `lib/` and `src/`. On glibc-based systems (e.g. NixOS), a system-level `error.h` with include guard `_ERROR_H` can
shadow gnulib's generated `error.h` (guard `_GL_ERROR_H`) when both are on `-isystem` paths. The corresponding
`GENERATED_SRCS` entry in `BUILD.bazel` maps `lib/m4-error.h` to the `lib/error.in.h` template, so there is no filename
collision. The gnulib template still chains to the system `error.h` via `#include_next` on GCC/Clang. This addresses the
same issue described in [jmillikin/rules_m4#23](https://github.com/jmillikin/rules_m4/pull/23).
