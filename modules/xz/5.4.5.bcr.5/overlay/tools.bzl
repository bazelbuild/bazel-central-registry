def multi_test(names = [], **kwargs):
    tests = []
    for name in names:
        native.cc_test(
            name = name,
            srcs = ["tests/" + name + ".c"],
            **kwargs
        )
        tests.append(":" + name)

    return tests
