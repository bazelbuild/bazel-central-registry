load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

def json_c_tests(names):
    # Formatted variants for test1 and test2
    cc_binary(
        name = "test1Formatted",
        srcs = ["test1.c", "parse_flags.c", "parse_flags.h"],
        local_defines = ["TEST_FORMATTED=1"],
        deps = ["//:json-c"],
    )

    cc_binary(
        name = "test2Formatted",
        srcs = ["test2.c", "parse_flags.c", "parse_flags.h"],
        local_defines = ["TEST_FORMATTED=1"],
        deps = ["//:json-c"],
    )

    for name in names:
        cc_binary(
            name = name,
            srcs = [name + ".c"] + (["parse_flags.c", "parse_flags.h"] if name in ["test1", "test2"] else []),
            deps = ["//:json-c"],
        )

        test_script = name + ".test"

        data = native.glob(["*.*"], exclude=["test*"]) + native.glob([name + ".*"]) + ["test-defs.sh"]

        if name == "test1":
            data += [":test1Formatted"] + native.glob(["test1Formatted*"])
        elif name == "test2":
            data += [":test2Formatted"] + native.glob(["test2Formatted*"])

        sh_test(
            name = "run_" + name,
            srcs = [test_script],
            data = data + [":" + name],
            env = {
                "srcdir": "tests",
                "top_builddir": ".",
                "USE_VALGRIND": "0",
            },
            use_bash_launcher = True,
        )
