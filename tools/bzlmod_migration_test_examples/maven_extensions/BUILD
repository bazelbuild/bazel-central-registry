load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "px_deps_bin",
    main_class = "org.antlr.v4.Tool",
    runtime_deps = [
        "@px_deps//:org_antlr_antlr4",
        "@px_deps//:com_google_jimfs_jimfs",
        "@px_deps//:com_google_truth_truth",
    ],
)
