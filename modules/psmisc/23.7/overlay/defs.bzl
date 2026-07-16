load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def _make_signames_impl(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)
    conf = cc_common.configure_features(ctx = ctx, cc_toolchain = cc_toolchain)
    cpp = cc_common.get_tool_for_action(feature_configuration = conf, action_name = ACTION_NAMES.c_compile)
    signames_c = ctx.actions.declare_file("signames.c")
    ctx.actions.write(signames_c, "#include <signal.h>")
    script = ctx.actions.declare_file("gen_signames_h.sh")
    ctx.actions.write(script, """\
#!/bin/sh
"$1" -dM -E "$2" | 
  tr -s '	 ' ' ' | 
  sort -n -k 3 | 
  sed -E 's:#define SIG([A-Z][A-Z]*[0-9]*) ([0-9][0-9]*).*$$:{\\ \\2,"\\1" },:p;d' | 
  grep -v '[0-9][0-9][0-9]' \\
  > "$3"
grep -q '{ 1,\"HUP\" },' "$3"
""")
    signames_h = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.run(
        outputs = [signames_h],
        inputs = depset(direct=[signames_c], transitive = [cc_toolchain.all_files]),
        arguments = [cpp, signames_c.path, signames_h.path],
        executable = script,
        env = {"LC_ALL": "C"},
        progress_message = "Generating signames",
    )
    return [DefaultInfo(files = depset([signames_h]))]

make_signames = rule(
    implementation = _make_signames_impl,
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    fragments = ["cpp"],
)
