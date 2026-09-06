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

genrule(
    name = "gen_integration_test_sh",
    outs = ["integration_test.sh"],
    cmd = """cat <<'EOF' >$@
#!/bin/bash
set -euxo pipefail
genhtml="$(rootpath @lcov//:genhtml)"
test "$$("$$genhtml" 2>&1 --version)" == "genhtml: LCOV version 2.1-1"
""",
    srcs = ["@lcov//:genhtml"],
    executable = True
)

sh_test(
    name = "integration_test",
    srcs = ["integration_test.sh"],
    data = ["@lcov//:genhtml"],
)
