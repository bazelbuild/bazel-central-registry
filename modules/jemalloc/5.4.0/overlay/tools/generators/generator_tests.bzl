"The tests of the generator tools, each declared with only what differs from the others"

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def runfile(label, prefix = ""):
    """An argument of an expect_failure_test: `prefix` followed by the path of the runfile `label`."""
    return struct(label = label, prefix = prefix)

def temporary(name, prefix = ""):
    """An argument of an expect_failure_test: `prefix` followed by the path of `name` in the test's TEST_TMPDIR."""
    return struct(name = name, prefix = prefix)

def _check_text(text):
    # cc_test args are tokenized like a Bourne shell and make variables in them are expanded.
    if "'" in text or "$" in text:
        fail("expect_failure_test text cannot hold ' or $: " + text)
    return text

def expect_failure_test(name, expected, command, arguments = [], data = [], env = {}):
    """Runs `command` with `arguments` and passes if it fails with `expected` in its stderr.

    Args:
      name: The test's name.
      expected: Text the command's stderr must contain.
      command: The tool to run, a label.
      arguments: The command's arguments, each a string, a runfile() or a temporary().
      data: Files the environment names.
      env: The command's environment.
    """
    driver_arguments = ["'{}'".format(_check_text(expected)), "$(rlocationpath {})".format(command)]
    runfiles = [command]
    for argument in arguments:
        if type(argument) == "string":
            driver_arguments.append("'--argument={}'".format(_check_text(argument)))
        elif hasattr(argument, "label"):
            driver_arguments.append("'--argument={}'".format(_check_text(argument.prefix)))
            driver_arguments.append("--runfile=$(rlocationpath {})".format(argument.label))
            runfiles.append(argument.label)
        else:
            driver_arguments.append("'--argument={}'".format(_check_text(argument.prefix)))
            driver_arguments.append("--temporary=" + _check_text(argument.name))
    cc_test(
        name = name,
        size = "small",
        srcs = ["expect_failure.cc"],
        args = driver_arguments,
        cxxopts = select({
            "//settings/compiler:msvc_compatible": ["/std:c++14"],
            "//conditions:default": ["-std=c++14"],
        }),
        data = runfiles + data,
        env = env,
        deps = [
            ":process",
            "@rules_cc//cc/runfiles",
        ],
    )

def leak_check_test(name, listing, expected_leak = None):
    """Runs private_namespace_leak_check on `listing`, with the fixture's exports, header and an empty lister stderr.

    Args:
      name: The test's name.
      listing: The archive's symbol listing, `nm -a` or dumpbin's.
      expected_leak: A symbol the check must report; the test then passes only if the check fails naming it.
    """
    data = [
        ":private_namespace_leak_fixture.export_syms",
        ":private_namespace_leak_fixture.h",
        ":private_namespace_leak_fixture_stderr",
        listing,
    ]
    env = {
        "PRIVATE_NAMESPACE_LEAK_EXPORTS": "$(rlocationpath :private_namespace_leak_fixture.export_syms)",
        "PRIVATE_NAMESPACE_LEAK_HEADER": "$(rlocationpath :private_namespace_leak_fixture.h)",
        "PRIVATE_NAMESPACE_LEAK_LISTING": "$(rlocationpath {})".format(listing),
        "PRIVATE_NAMESPACE_LEAK_PREFIX": "je_",
        "PRIVATE_NAMESPACE_LEAK_STDERR": "$(rlocationpath :private_namespace_leak_fixture_stderr)",
        "PRIVATE_NAMESPACE_LEAK_SYM_PREFIX": "",
    }
    if expected_leak:
        expect_failure_test(
            name = name,
            expected = expected_leak,
            command = ":private_namespace_leak_check",
            data = data,
            env = env,
        )
        return
    cc_test(
        name = name,
        size = "small",
        srcs = ["private_namespace_leak_check.cc"],
        cxxopts = select({
            "//settings/compiler:msvc_compatible": ["/std:c++14"],
            "//conditions:default": ["-std=c++14"],
        }),
        data = data,
        env = env,
        deps = [
            ":private_namespace_listing",
            "@rules_cc//cc/runfiles",
        ],
    )
