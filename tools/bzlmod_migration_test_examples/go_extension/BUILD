load("@io_bazel_rules_go//go:def.bzl", "go_binary")
load("@bazel_gazelle//:def.bzl", "gazelle")

gazelle(name = "gazelle")

go_binary(
    name = "go_bin",
    srcs = ["test.go"],
    deps = [
        "@org_golang_google_grpc//codes",
        "@org_golang_x_net//context",
        "@org_golang_x_text//language",
    ]
)