# Patches

This version ships two small patches on top of upstream GNU m4 1.4.20:

- **`windows-binary-mode.patch`** — At the start of `output_init()` in `src/output.c`, call `SET_BINARY(STDOUT_FILENO)` when `SET_BINARY` is defined. On Windows, the C runtime defaults text mode on stdout, which translates newlines to CRLF. m4 must write its output in binary mode so generated files are not corrupted; this matches the usual MinGW/MSVC pattern for binary-safe stdout.

- **`stdint-comment-subst.patch`** — In `lib/stdint.in.h`, the comment that mentions the autoconf token `@NEXT_STDINT_H@` is rewritten so the `@...@` sequence is split with spaces (`@ NEXT_STDINT_H @`). That keeps the comment readable but avoids accidental processing of the token as a substitution placeholder by tooling that scans for `@NAME@` patterns during the Bazel build.
