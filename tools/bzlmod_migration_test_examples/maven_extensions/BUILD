load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "px_deps_bin",
    main_class = "org.antlr.v4.Tool",
    runtime_deps = [
        "@px_deps//:org_antlr_antlr4",
        "@px_deps//:com_google_jimfs_jimfs",
        "@px_deps//:com_google_truth_truth",
        "@maven//:org_apache_santuario_xmlsec",
        "@maven//:aopalliance_aopalliance",
    ],
)

alias(
    name = "biz_aQute_bnd",
    actual = "@maven//:biz_aQute_bnd",
)

alias(
    name = "com_google_truth_truth",
    actual = "@maven//:com_google_truth_truth",
)
