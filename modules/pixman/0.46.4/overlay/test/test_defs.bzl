load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_test")

def pixman_tests(tests, progs):
    for test_name in tests:

        if test_name in ["cover-test", "fence-image-self-test", "neg-stride-test"]:
            target_compatible_with = select({
                "@platforms//os:windows": ["@platforms//:incompatible"],
                "//conditions:default": [],
            })
        else:
            target_compatible_with = None

        cc_test(
            name = test_name,
            srcs = [test_name + ".c"],
            defines = ["HAVE_CONFIG_H"],
            linkstatic = True,
            deps = [
                "//pixman:pixman",
                "//test/utils:testutils",
            ],
            target_compatible_with = target_compatible_with,
            timeout = "long",
        )

    for prog_name in progs:
        cc_binary(
            name = prog_name,
            srcs = [prog_name + ".c"],
            defines = ["HAVE_CONFIG_H"],
            linkstatic = True,
            deps = [
                "//pixman:pixman",
                "//test/utils:testutils",
            ],
        )
