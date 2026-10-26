# Patches

This version ships the following patches on top of upstream GNU m4 1.4.21:

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

Earlier versions also carried `error-h-shadowing.patch`, which renamed gnulib's `error.h` to `m4-error.h` because a
system `error.h` on an `-isystem` path could shadow the generated one. The converter serves the generated gnulib
headers from `lib/_gnulib_gen` through `strip_include_prefix` (an `-I` path, searched before every `-isystem` path),
so the patch is no longer needed and was dropped.
