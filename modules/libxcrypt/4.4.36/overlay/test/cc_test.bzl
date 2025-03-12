load("@rules_cc//cc:defs.bzl", _cc_test = "cc_test")
load("@rules_python//python:defs.bzl", "py_test")

visibility("//test")

def cc_test(name, size, tags, **kw):
    cc = "{}.cc".format(name)
    _cc_test(
        name = cc,
        tags = ["manual"],
        **kw,
    )

    main = Label("bazel.py")

    py_test(
        name = name,
        main = main,
        srcs = [main],
        data = [":{}".format(cc)],
        args = ["$(rlocationpath {})".format(cc)],
        deps = ["@rules_python//python/runfiles"],
    )
