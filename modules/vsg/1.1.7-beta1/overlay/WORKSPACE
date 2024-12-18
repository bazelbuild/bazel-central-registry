load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_7zip",
    strip_prefix = "rules_7zip-e95ba876db445cf2c925c02c4bc18ed37a503fd8",
    url = "https://github.com/zaucy/rules_7zip/archive/e95ba876db445cf2c925c02c4bc18ed37a503fd8.zip",
    sha256 = "b66e1c712577b0c029d4c94228dba9c8aacdcdeb88c3b1eeeffd00247ba5a856",
)

load("@rules_7zip//:setup.bzl", "setup_7zip")

setup_7zip()

# Replace with latest repository commit hash
RULES_VULKAN_COMMIT = "29fbfc1b733365ddc4e798f09455e066528718c6"

http_archive(
    name = "com_github_zaucy_rules_vulkan",
    strip_prefix = "rules_vulkan-{}".format(RULES_VULKAN_COMMIT),
    url = "https://github.com/zaucy/rules_vulkan/archive/{}.zip".format(RULES_VULKAN_COMMIT),
)

load("@com_github_zaucy_rules_vulkan//:repo.bzl", "vulkan_repos")

vulkan_repos()
