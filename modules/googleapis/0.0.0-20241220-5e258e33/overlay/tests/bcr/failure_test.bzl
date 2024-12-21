load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _cc_proto_library_fails_with_message_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, """Add 'bazel_dep(name = "googleapis-cc", version = "0.1.0")' to your MODULE.bazel file to use 'cc_proto_library' targets in 'googleapis'.""")
    return analysistest.end(env)

cc_proto_library_fails_with_message_test = analysistest.make(
    _cc_proto_library_fails_with_message_test_impl,
    expect_failure = True,
)
