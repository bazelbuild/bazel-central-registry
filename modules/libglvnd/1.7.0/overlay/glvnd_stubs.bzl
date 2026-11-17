"""Link-time-only libglvnd stub shared libraries.

Each stub exports exactly the symbols listed in upstream's src/<lib>/*.symbols
file and carries the real library's SONAME, so binaries linked against it get
the same DT_NEEDED entry they would get from a system libglvnd. The stub is
passed to the linker as an interface library, so it is never added to runfiles
or to the binary's RUNPATH: at runtime the dynamic loader finds the system
libglvnd and the installed vendor driver.
"""

load("@rules_cc//cc:defs.bzl", "CcInfo", "cc_common")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")

GlvndStubInfo = provider(
    doc = "A libglvnd stub shared library.",
    fields = {
        "library": "File: the stub shared library.",
        "link_name": "Unversioned library name, e.g. 'GL' for -lGL.",
        "soname": "SONAME of the real library, e.g. 'libGL.so.1'.",
    },
)

def _glvnd_stub_library_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    src = ctx.actions.declare_file(ctx.label.name + ".c")
    ctx.actions.run(
        executable = ctx.executable._stub_gen,
        arguments = [ctx.file.symbols.path, src.path],
        inputs = [ctx.file.symbols],
        outputs = [src],
        mnemonic = "GlvndStubGen",
        progress_message = "Generating libglvnd stub source for " + ctx.attr.soname,
    )

    (_, compilation_outputs) = cc_common.compile(
        name = ctx.label.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        srcs = [src],
        user_compile_flags = ["-fPIC", "-w"],
    )
    link_outputs = cc_common.link(
        name = ctx.label.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_outputs = compilation_outputs,
        output_type = "dynamic_library",
        user_link_flags = ["-Wl,-soname," + ctx.attr.soname],
    )
    lib = link_outputs.library_to_link
    so_file = lib.resolved_symlink_dynamic_library or lib.dynamic_library

    library_to_link = cc_common.create_library_to_link(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        interface_library = so_file,
    )
    linking_context = cc_common.create_linking_context(
        linker_inputs = depset([cc_common.create_linker_input(
            owner = ctx.label,
            libraries = depset([library_to_link]),
        )]),
    )
    return [
        DefaultInfo(files = depset([so_file])),
        CcInfo(linking_context = linking_context),
        GlvndStubInfo(
            library = so_file,
            link_name = ctx.attr.link_name,
            soname = ctx.attr.soname,
        ),
    ]

glvnd_stub_library = rule(
    implementation = _glvnd_stub_library_impl,
    doc = "Builds one link-time-only libglvnd stub from an upstream .symbols file.",
    attrs = {
        "link_name": attr.string(mandatory = True),
        "soname": attr.string(mandatory = True),
        "symbols": attr.label(mandatory = True, allow_single_file = [".symbols"]),
        "_stub_gen": attr.label(
            default = Label("//:gl_stub_gen"),
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
    provides = [CcInfo, GlvndStubInfo],
)

def _glvnd_libdir_impl(ctx):
    libdir = ctx.actions.declare_directory(ctx.label.name)
    stubs = [s[GlvndStubInfo] for s in ctx.attr.stubs]
    args = ctx.actions.args()
    args.add(libdir.path)
    for s in stubs:
        args.add_all([s.library.path, s.soname, "lib{}.so".format(s.link_name)])
    ctx.actions.run_shell(
        inputs = [s.library for s in stubs],
        outputs = [libdir],
        arguments = [args],
        command = """
set -eu
out="$1"; shift
mkdir -p "$out"
while [ "$#" -gt 0 ]; do
  cp "$1" "$out/$2"
  cp "$1" "$out/$3"
  shift 3
done
""",
        mnemonic = "GlvndStubLibdir",
        progress_message = "Assembling libglvnd stub library directory",
    )
    return [DefaultInfo(files = depset([libdir]))]

glvnd_libdir = rule(
    implementation = _glvnd_libdir_impl,
    doc = """A directory holding each stub under its SONAME and its unversioned
link name (libGL.so, libEGL.so, ...), for third-party builds that hard-code
-lGL/-lEGL and need a -L search path. Never put this directory on a runtime
library path (RUNPATH, LD_LIBRARY_PATH): the stubs are empty functions.""",
    attrs = {
        "stubs": attr.label_list(mandatory = True, providers = [GlvndStubInfo]),
    },
)
