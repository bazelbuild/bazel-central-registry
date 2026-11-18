"""Helper macro for declaring the upstream `tests/TESTS` shell scripts as tests."""

load("@bazel_skylib//rules:native_binary.bzl", "native_test")

_RUNNER = Label("//tests:run_grep_test")
_TEST_DATA = Label("//tests:upstream_test_data")

# What the runner is told about, in the order it takes them on its command
# line (see `main()` in run_grep_test.cc).
_RUNNER_INPUTS = [
    Label("//:grep"),
    Label("//tests:init.sh"),
    Label("//tests:get-mb-cur-max"),
    Label("//:config"),
]

def declared_tests(*, mirror, omitted, present):
    """Subtract the omitted tests from the `tests/Makefile.am` `TESTS` mirror.

    Also guards the mirror against going stale: at the next version bump a
    renamed or removed upstream test would otherwise silently drop its
    coverage. (The reverse -- a *new* upstream test missing from the mirror --
    cannot be caught here and needs a manual diff.)

    Args:
        mirror: Verbatim copy of upstream's `TESTS`.
        omitted: `{test name: reason}` for the tests deliberately not declared.
        present: The names actually shipped in the tarball's `tests/`.

    Returns:
        The sorted list of test names to declare.
    """
    missing = [t for t in mirror if t not in present]
    unused = [t for t in omitted if t not in mirror]
    if missing or unused:
        fail("tests/Makefile.am TESTS mirror is stale. Not in the tarball: {}. Omitted but not listed: {}.".format(
            missing,
            unused,
        ))
    return [t for t in mirror if t not in omitted]

def grep_test(*, name):
    """Declare one upstream `tests/<name>` script as a test.

    Every test is the same binary, `//tests:run_grep_test`, told which script
    to run. It reconstructs the directory layout and environment that
    `tests/Makefile.am`'s `TESTS_ENVIRONMENT` would have provided (a build
    tree with `src/grep` next to `tests/`, the `srcdir`/`abs_top_builddir`
    variables, `PATH` pointing at the built binaries, and file descriptor 9
    aliased to stderr for `init.cfg`) and then runs the script through
    `/bin/sh` -- or, on Windows, the shell `BAZEL_SH` names. The whole
    `tests/` directory is staged for each test: the scripts source
    `init.sh`/`init.cfg` and several reach for siblings such as `bre.awk` or
    `khadafy.lines`.

    Upstream tests signal "not applicable here" with exit status 77 -- most
    often a missing locale. Bazel has no runtime-skip status, so the runner
    maps 77 to 0 after printing a `SKIPPED:` banner; check the test log to
    see which ones did not actually execute.

    The target is named `<name>_test` rather than `<name>`: the script itself
    is a source file in this package and is passed through `data`, and a rule
    sharing that name would shadow the file into a self-edge.

    Args:
        name: Name of the upstream script in `tests/`.

    Returns:
        The label string of the declared test target.
    """
    target = "{}_test".format(name)
    native_test(
        name = target,
        size = "small",
        src = _RUNNER,
        args = ["$(rlocationpath {})".format(input) for input in _RUNNER_INPUTS] + [name],
        data = [_TEST_DATA] + _RUNNER_INPUTS,
        # The runner itself is portable and the suite does run under MSYS2's
        # bash (65 of 124 pass on a Windows box), but the rest need
        # /dev/full, directories that open(), SIGPIPE, or expect `grep:`
        # rather than `grep.exe:` in diagnostics.  Until those are triaged
        # into a per-platform omission list, Windows keeps the portable
        # smoke test only.
        target_compatible_with = select({
            "@platforms//os:windows": ["@platforms//:incompatible"],
            "//conditions:default": [],
        }),
    )
    return ":" + target
