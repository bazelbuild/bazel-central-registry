load("@rules_perl//perl:perl.bzl", "perl_binary", "perl_library")

package(default_visibility = ["//visibility:public"])

exports_files(["**/*"])

perl_library(
    name = "liblcov",
    srcs = glob(["lib/**/*"]),
    deps = ["@cpan_deps"],
)

[
    perl_binary(
        name = bin,
        srcs = ["bin/" + bin],
        deps = [":liblcov"],
    )
    for bin in [
        "fix.pl",
        "gendesc",
        "genhtml",
        "geninfo",
        "genpng",
        "get_changes.sh",
        "get_version.sh",
        "lcov",
        "perl2lcov",
        "py2lcov",
        "xml2lcov",
    ]
]

sh_test(
    name = "integration_test",
    srcs = ["integration_test.sh"],
    data = ["@lcov//:genhtml"],
    args = ["$(rootpath @lcov//:genhtml)"],
)
