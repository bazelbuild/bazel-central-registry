load("@rules_license//rules:license.bzl", "license")
load(":openusd_targets.bzl", "define_openusd_targets")

package(
    default_applicable_licenses = [":license"],
    default_visibility = ["//visibility:public"],
)

exports_files(["LICENSE.txt"])

# Note: OpenUSD uses a derivative of the Apache 2.0 license called the
# Tomorrow Open Source Technology License 1.0.
license(
    name = "license",
    package_name = "openusd",
    license_kinds = [],
    license_text = ":LICENSE.txt",
)

define_openusd_targets()
