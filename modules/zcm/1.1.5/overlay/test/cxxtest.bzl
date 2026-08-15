"""Helper macro for generating and running CxxTest suites."""

load("@rules_cc//cc:defs.bzl", "cc_test")

def cxxtest_test(name, src, extra_srcs = [], copts = [], env = {}, deps = [], **kwargs):
    runner_name = "%s_runner" % name
    native.genrule(
        name = runner_name,
        srcs = [src],
        outs = ["%s.cpp" % runner_name],
        cmd = (
            "$(execpath @cxxtest//:cxxtestgen) --error-printer -o $@ $< && " +
            "sed -i 's|#include \".*/\\(.*\\.hpp\\)\"|#include \"\\1\"|g' $@"
        ),
        tools = ["@cxxtest//:cxxtestgen"],
    )

    test_env = {
        "ZCM_LOCK_DIR": "/tmp",
        "ZCM_DEFAULT_URL": "ipc",
    }
    test_env.update(env)

    cc_test(
        name = name,
        srcs = [
            ":" + runner_name,
            src,
        ] + extra_srcs,
        copts = [
            "-I.",
            "-Izcm",
        ] + copts,
        env = test_env,
        deps = [
            "@cxxtest//:cxxtest",
            "@zcm//:zcm",
            "@zcm//:zcm-coretypes",
        ] + deps,
        **kwargs
    )
