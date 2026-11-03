"""Helper macro for declaring upstream gawk awk-based sh_tests."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

_GAWK = Label("//:gawk")

def incompat_if(setting):
    """Return a `target_compatible_with` value that skips when `setting` matches."""
    return select({
        setting: ["@platforms//:incompatible"],
        "//conditions:default": [],
    })

def awk_test(
        *,
        name,
        awk,
        ok,
        input = None,
        extra_args = "",
        gawk = _GAWK,
        category = None,
        target_compatible_with = []):
    """Declare a single awk-based `sh_test` against an upstream `.ok` baseline.

    Backed by `//test:run_awk_test.sh` which sources `runfiles.bash` to
    resolve runfile-relative paths, then `chdir`s to a tmp dir holding
    short-named copies of the inputs (so error messages report basenames
    matching upstream `.ok` files), runs gawk, and diffs the output.

    All inputs are passed explicitly — callers in
    [test/BUILD.bazel](test/BUILD.bazel) build the upstream test name lists
    and pass the matching file labels here.

    Args:
        name: Test target name. If `category` is set, the actual `sh_test`
            label becomes `<category>_<name>_test`.
        awk: Label of the `.awk` driver source.
        ok: Label of the `.ok` golden output.
        input: Optional label of a `.in` stdin file. Pass `None` when the
            test produces output without reading stdin.
        extra_args: Space-separated extra arguments passed to gawk (e.g.
            `"--lint"`, `"--re-interval"`).
        gawk: Label of the gawk executable. Default is `//:gawk`; override
            with `//test:gawk_filefuncs` (or similar) for SHLIB tests.
        category: Optional string used to namespace the generated test name
            so `defref` (BASIC) and `lint_defref_test` (NEED_LINT) don't
            collide.
        target_compatible_with: Forwarded to the underlying `sh_test` so
            callers can skip the test in configurations where it can't run
            (e.g. SHLIB tests under `--//:disable_extensions=true`).
    """
    data = [
        gawk,
        awk,
        ok,
    ]
    args = [
        "$(rlocationpath {})".format(gawk),
        "$(rlocationpath {})".format(ok),
        "$(rlocationpath {})".format(awk),
    ]
    if input != None:
        data.append(input)
        args.append("$(rlocationpath {})".format(input))
    else:
        # Sentinel for "no input file". Bazel strips empty-string args from
        # the args list, so we can't use "" as a placeholder.
        args.append("__no_input__")
    if extra_args:
        args.extend(extra_args.split(" "))

    test_name = name
    if category:
        test_name = "{}_{}_test".format(category, name)

    sh_test(
        name = test_name,
        srcs = [Label("//test:run_awk_test.sh")],
        args = args,
        data = data,
        target_compatible_with = target_compatible_with,
        deps = [
            Label("@rules_shell//shell/runfiles"),
        ],
    )
