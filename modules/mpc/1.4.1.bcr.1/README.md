# MPC 1.4.1.bcr.1

Bazel port of [GNU MPC](https://www.multiprecision.org/mpc/) using
`rules_cc_autoconf` for platform-specific configuration.

## Patches

### `remove_pregenerated_headers.patch`

The upstream tarball ships pre-generated `src/mpc.h` and `src/mpc-impl.h`
(produced by `./configure` on the release machine) alongside the `.in`
templates. These pre-generated copies hardcode `MPC_HAVE_COMPLEX_H=1`,
which is incorrect on Windows/MSVC where complex arithmetic operators are
unsupported. They also conflict with the `autoconf_hdr`-generated versions
under Bazel's strict include sandboxing.

This patch deletes both files so that only the `autoconf_hdr`-generated
versions (from the `.in` templates) exist, with the correct
`MPC_HAVE_COMPLEX_H` value per platform.

### `bazel_test_srcdir.patch`

MPC's test framework locates `.dat` and `.dsc` data files via
`getenv("srcdir")`. Under Bazel, test data files live in the runfiles tree
at paths that vary across Bazel versions and platforms. This patch adds a
`MPC_BAZEL_TEST`-guarded code path to `open_datafile.c` and `read_data.c`
that uses the `rules_cc` C++ runfiles library (via `bazel/runfiles_util.h`)
to resolve data file paths from the `MPC_SRCDIR` environment variable.
