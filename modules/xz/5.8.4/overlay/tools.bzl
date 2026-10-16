load("@rules_cc//cc:cc_test.bzl", "cc_test")

def multi_test(names = [], **kwargs):
    tests = []
    for name in names:
        cc_test(
            name = name,
            srcs = ["tests/" + name + ".c"],
            **kwargs
        )
        tests.append(":" + name)

    return tests
