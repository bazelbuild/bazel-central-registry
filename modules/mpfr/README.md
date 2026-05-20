# mpfr

Bazel overlay for [GNU MPFR](https://www.mpfr.org/) (Multiple Precision
Floating-Point Reliable).

## Porting a new version

1. Create the new version directory (`modules/mpfr/X.Y.Z/`) from the previous version.

2. Download and extract the new source tarball.

3. Regenerate `config.in` from the source tree:

   ```shell
   python3 modules/mpfr/gen_mpfr_config_in.py /path/to/mpfr-X.Y.Z --version X.Y.Z
   ```

   This parses `configure.ac`, `acinclude.m4`, and the `m4/` directory to
   extract every symbol the autoconf build system may `#define`, then writes
   `overlay/config.in` with the corresponding `#undef` directives. The script
   is version-agnostic and should work for any MPFR release.

4. Manually inspect the upstream autoconf files for changes that affect the
   Bazel overlay:

   - **`configure.ac`** -- look for new `AC_ARG_ENABLE` / `AC_ARG_WITH`
     options that need corresponding `bool_flag` or `string_flag` entries
     and `AC_DEFINE` checks in `BUILD.bazel`.
   - **`acinclude.m4`** (`MPFR_CONFIGS` macro) -- look for new
     `AC_CHECK_HEADERS`, `AC_CHECK_FUNCS`, `AC_DEFINE`, or
     `AC_TRY_COMPILE` checks that need autoconf entries in `BUILD.bazel`.
   - **`src/Makefile.am`** (`libmpfr_la_SOURCES`) -- check for added or
     removed source files and update the glob excludes / `textual_hdrs`
     in `BUILD.bazel` accordingly.
   - **`tests/Makefile.am`** (`TESTS_NO_TVERSION`) -- check for added or
     removed tests and update the `_MPFR_TESTS` list in
     `tests/BUILD.bazel`.
