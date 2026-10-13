"""Declares the upstream `tests/Makefile.am` `TESTS` shell scripts as tests."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

visibility("private")

_RUNNER = Label("//tests:run_gzip_test")

# What the runner is told about, in the order it takes them on its command
# line (see the usage note in run_gzip_test.sh).
_RUNNER_INPUTS = [
    Label("//tests:init.sh"),
    Label("//:config"),
]

_PROGRAMS = Label("//:programs")

_TEST_DATA = Label("//tests:upstream_test_data")

def declared_tests(*, mirror, present):
    """Guard the `tests/Makefile.am` `TESTS` mirror against going stale.

    At the next version bump a renamed or removed upstream test would
    otherwise silently drop its coverage.  (The reverse -- a *new* upstream
    test missing from the mirror -- cannot be caught here and needs a manual
    diff.)

    Args:
        mirror: Verbatim copy of upstream's `TESTS`.
        present: The names actually shipped in the tarball's `tests/`.

    Returns:
        `mirror`, once every entry has been found.
    """
    missing = [t for t in mirror if t not in present]
    if missing:
        fail("tests/Makefile.am TESTS mirror is stale. Not in the tarball: {}.".format(missing))
    return mirror

def gzip_test(*, name, size = "small"):
    """Declare one upstream `tests/<name>` script as a test.

    Every test is the same script, `//tests:run_gzip_test`, told which
    upstream script to run; see its header for the layout and environment it
    rebuilds and how an upstream skip (exit 77) is reported.

    The target is named `<name>_test` rather than `<name>`: the script itself
    is a source file in this package and is passed through `data`, and a rule
    sharing that name would shadow the file into a self-edge.

    Args:
        name: Name of the upstream script in `tests/`.
        size: Bazel test size.
    """
    sh_test(
        name = "{}_test".format(name),
        size = size,
        srcs = [_RUNNER],
        args = [name] + [
            "$(rlocationpath {})".format(input)
            for input in _RUNNER_INPUTS
        ] + ["$(rlocationpaths {})".format(_PROGRAMS)],
        data = [_TEST_DATA, _PROGRAMS] + _RUNNER_INPUTS,
        deps = ["@rules_shell//shell/runfiles"],
    )
