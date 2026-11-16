"""Builds link-time-only libglvnd stub shared libraries (libGL.so.1, libGLX.so.0, libOpenGL.so.0, libEGL.so.1)."""

load("@rules_cc//cc:defs.bzl", "CcInfo", "cc_common")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")

def _glvnd_stubs_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    out_gl_c = ctx.actions.declare_file(ctx.label.name + "_gl.c")
    out_glx_c = ctx.actions.declare_file(ctx.label.name + "_glx.c")
    out_opengl_c = ctx.actions.declare_file(ctx.label.name + "_opengl.c")
    out_egl_c = ctx.actions.declare_file(ctx.label.name + "_egl.c")

    hdr_depsets = []
    for dep in ctx.attr.hdr_deps:
        if CcInfo in dep:
            hdr_depsets.append(dep[CcInfo].compilation_context.headers)
        else:
            hdr_depsets.append(dep[DefaultInfo].files)
    all_hdrs = depset(transitive = hdr_depsets)
    hdr_args = [
        f.path
        for f in all_hdrs.to_list()
        if f.path.endswith(".h") and "wgl" not in f.basename
    ]

    ctx.actions.run(
        executable = ctx.executable._stub_gen,
        arguments = [
            out_gl_c.path,
            out_glx_c.path,
            out_opengl_c.path,
            out_egl_c.path,
        ] + hdr_args,
        inputs = all_hdrs,
        outputs = [out_gl_c, out_glx_c, out_opengl_c, out_egl_c],
        mnemonic = "GlvndStubGen",
        progress_message = "Generating Khronos libglvnd stub sources",
    )

    stub_specs = [
        ("GL", "libGL.so.1", out_gl_c),
        ("GLX", "libGLX.so.0", out_glx_c),
        ("OpenGL", "libOpenGL.so.0", out_opengl_c),
        ("EGL", "libEGL.so.1", out_egl_c),
    ]

    libraries_to_link = []
    so_files = []
    for lib_short, soname, src_c in stub_specs:
        (_, comp_outputs) = cc_common.compile(
            name = ctx.label.name + "_" + lib_short,
            actions = ctx.actions,
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
            srcs = [src_c],
            user_compile_flags = ["-fPIC", "-O2", "-w"],
        )
        link_outputs = cc_common.link(
            name = ctx.label.name + "_" + lib_short,
            actions = ctx.actions,
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
            compilation_outputs = comp_outputs,
            output_type = "dynamic_library",
            user_link_flags = ["-Wl,-soname," + soname],
        )
        so_file = link_outputs.library_to_link.resolved_symlink_dynamic_library or link_outputs.library_to_link.dynamic_library
        so_files.append((lib_short, soname, so_file))
        libraries_to_link.append(
            cc_common.create_library_to_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                dynamic_library = so_file,
            ),
        )

    # A single directory holding every stub under both its SONAME and its
    # unversioned link name (libGL.so, libEGL.so, ...), for consumers whose
    # upstream linkopts hard-code -lGL/-lEGL and need a -L search path.
    libdir = ctx.actions.declare_directory(ctx.label.name + "_libdir")
    copy_cmds = ["mkdir -p {}".format(libdir.path)]
    for lib_short, soname, so_file in so_files:
        copy_cmds.append("cp {} {}/{}".format(so_file.path, libdir.path, soname))
        copy_cmds.append("cp {} {}/lib{}.so".format(so_file.path, libdir.path, lib_short))
    ctx.actions.run_shell(
        inputs = [f for _, _, f in so_files],
        outputs = [libdir],
        command = " && ".join(copy_cmds),
        mnemonic = "GlvndStubLibdir",
        progress_message = "Assembling libglvnd stub library directory",
    )

    linker_input = cc_common.create_linker_input(
        owner = ctx.label,
        libraries = depset(libraries_to_link),
        user_link_flags = [
            "-Wl,--no-as-needed",
        ],
    )
    linking_context = cc_common.create_linking_context(
        linker_inputs = depset([linker_input]),
    )
    return [
        DefaultInfo(files = depset([libdir])),
        CcInfo(linking_context = linking_context),
    ]

glvnd_stubs = rule(
    implementation = _glvnd_stubs_impl,
    attrs = {
        "hdr_deps": attr.label_list(mandatory = True),
        "_stub_gen": attr.label(
            default = Label("//:gl_stub_gen"),
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
    provides = [CcInfo],
)
