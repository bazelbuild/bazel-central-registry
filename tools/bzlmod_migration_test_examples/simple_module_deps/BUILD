load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_cc//cc:defs.bzl", "cc_library", "cc_binary")
load("@rules_java//java:defs.bzl", "java_library", "java_binary")
load("@rules_shell//shell:sh_library.bzl", "sh_library")
load("@com_google_protobuf//bazel:cc_proto_library.bzl", "cc_proto_library")
load("@com_google_protobuf//bazel:proto_library.bzl", "proto_library")

cc_library(
    name = "cc_lib",
    srcs = ["test.cc"],
    visibility = ["//visibility:public"], 
)

cc_binary(
    name = "cc_bin",
    deps = [":cc_lib"],
)

java_library(
    name = "java_lib",
    srcs = ["Test.java"],
    visibility = ["//visibility:public"],
)

java_binary(
    name = "java_bin",
    main_class = "Test",
    runtime_deps = [":java_lib"],
)

bzl_library(
    name = "rules-java-docs",
    srcs = [
        "@rules_java//java:defs.bzl",
    ],
    deps = [
        "@bazel_gazelle//:def",
        "//external:gazelle_bind"
    ]
)

sh_library(name='sh_lib')

proto_library(
    name = "proto_lib",
    srcs = ["test.proto"]
)

cc_proto_library(
    name = "cc_proto_lib",
    deps = [":proto_lib"]
)
