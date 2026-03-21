load("@rules_cc//cc:defs.bzl", "cc_test")

TEST_DEFINES = [
    "CURL_ENABLED",
    "PROJ_HAS_PTHREADS",
    "TIFF_ENABLED",
]

PROJ_RUNTIME_DATA = [
    "@proj//:proj_db",
    "@proj//:data/proj.ini",
    "@proj//:proj_runtime_data",
]

def proj_wrapped_test(name, srcs, extra_data = [], source_data_marker = None, timeout = None, extra_args = []):
    args = [
        "--proj-test-proj-db=$(rootpath @proj//:proj_db)",
        "--proj-test-proj-ini=$(rootpath @proj//:data/proj.ini)",
    ] + extra_args
    if source_data_marker != None:
        args.append("--proj-test-source-data-marker=$(rootpath %s)" % source_data_marker)

    cc_test(
        name = name,
        srcs = [
            "bazel_test_main.cpp",
            "unit/gtest_include.h",
            "unit/test_primitives.hpp",
        ] + srcs,
        args = args,
        data = PROJ_RUNTIME_DATA + extra_data,
        defines = TEST_DEFINES,
        deps = [
            "@googletest//:gtest",
            "@proj",
        ],
        timeout = timeout,
    )
