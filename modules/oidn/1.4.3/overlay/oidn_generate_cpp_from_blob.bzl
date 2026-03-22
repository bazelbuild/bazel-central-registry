load("@rules_cc//cc:cc_library.bzl", "cc_library")

def generate_cpp_from_blob_cc_library(name, **kwargs):
    src = "@oidn-weights//:" + name
    cpp_out = "weights/" + name[0:-4] + ".cpp"
    header_out = "weights/" + name[0:-4] + ".h"
    native.genrule(
        name = "%s_weights_gen" % name,
        srcs = [src],
        outs = [
            cpp_out,
            header_out,
        ],
        cmd = ("./$(location //:blob_to_cpp) $(location {src}) " +
               "-o $(location {cpp_out}) " +
               "-H $(location {header_out}) " +
               "-n oidn::blobs::weights").format(
            src = src,
            cpp_out = cpp_out,
            header_out = header_out,
        ),
        tools = ["//:blob_to_cpp"],
    )
    cc_library(
        name = name,
        srcs = [cpp_out],
        hdrs = [header_out],
        **kwargs
    )
