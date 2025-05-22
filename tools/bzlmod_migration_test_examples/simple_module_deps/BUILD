load("@rules_cc//cc:defs.bzl", "cc_library", "cc_binary")
load("@rules_java//java:defs.bzl", "java_library", "java_binary")
load("@rules_shell//shell:sh_library.bzl", "sh_library")

cc_library(
    name = "cc_lib",
    srcs = ["test.cc"],
    visibility = ["//visibility:public"], 
)

cc_binary(
    name = "cc_bin",
    deps = [
        ":cc_lib", 
    ],
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

sh_library(name='sh_lib')