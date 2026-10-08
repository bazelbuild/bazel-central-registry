"""Bazel rule that compiles capnp schemas into Rust source via `capnpc-rust`.

The rule emits a `BuildInfo` provider with `out_dir` set to a directory
populated with `<name>_capnp.rs` files. Adding it to a `rust_library`'s deps
makes `OUT_DIR` resolve to that directory at compile time, so upstream code
that uses `include!(concat!(env!("OUT_DIR"), "/<X>_capnp.rs"))` works as-is.
"""

load("@rules_rust//rust:rust_common.bzl", "BuildInfo")

def _capnp_rust_gen_impl(ctx):
    out_dir = ctx.actions.declare_directory(ctx.label.name + ".out_dir")
    args = ctx.actions.args()
    args.add("--capnp", ctx.executable._capnp_tool)
    args.add_all([out_dir], before_each = "--out-dir", expand_directories = False)

    # Default the src_prefix to the common directory of all srcs so the
    # generated files land at `<out_dir>/<basename>_capnp.rs` (which is what
    # upstream's `schema.rs` expects).
    src_prefix = ctx.attr.src_prefix
    if not src_prefix and ctx.files.srcs:
        src_prefix = ctx.files.srcs[0].dirname
        for f in ctx.files.srcs[1:]:
            if f.dirname != src_prefix:
                src_prefix = ""
                break
    if src_prefix:
        args.add("--src-prefix", src_prefix)
    if ctx.attr.parent_module:
        args.add("--parent-module", ctx.attr.parent_module)

    # `import "/capnp/foo.capnp"` lookups: pass one `--import-path` per
    # distinct parent-of-`capnp/` directory among the system include files.
    # Files in `system_includes` must sit at `<root>/capnp/<name>.capnp`.
    system_files = ctx.files.system_includes
    import_roots = {f.dirname[:-len("/capnp")]: True for f in system_files if f.dirname.endswith("/capnp")}
    for root in import_roots:
        args.add("--import-path", root)

    args.add("--")
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        executable = ctx.executable._shim,
        arguments = [args],
        inputs = ctx.files.srcs + system_files,
        tools = [ctx.executable._capnp_tool, ctx.executable._shim],
        outputs = [out_dir],
        mnemonic = "CapnpcRust",
        progress_message = "CapnpcRust %{label}",
    )

    return [
        DefaultInfo(files = depset([out_dir])),
        BuildInfo(
            out_dir = out_dir,
            rustc_env = None,
            dep_env = None,
            flags = None,
            link_search_paths = None,
            linker_flags = None,
            compile_data = depset([]),
        ),
    ]

capnp_rust_gen = rule(
    implementation = _capnp_rust_gen_impl,
    doc = "Run `capnp compile` with the `capnpc-rust` plugin and expose the " +
          "output directory as a rules_rust `BuildInfo` provider.",
    attrs = {
        "parent_module": attr.string(
            doc = "`::`-separated parent module path forwarded to " +
                  "`capnpc::CompilerCommand::default_parent_module`.",
        ),
        "src_prefix": attr.string(
            doc = "Prefix stripped from `srcs` paths when computing the " +
                  "output file names (passed to `capnpc::CompilerCommand::src_prefix`).",
        ),
        "srcs": attr.label_list(
            allow_files = [".capnp"],
            mandatory = True,
            doc = "Schema files to compile.",
        ),
        "system_includes": attr.label_list(
            allow_files = [".capnp"],
            default = [Label("@capnp-cpp//src/capnp:capnp_system_library")],
            doc = "Additional `.capnp` files that satisfy `import \"/capnp/...\"` " +
                  "lookups. Each file must live at `<root>/capnp/<name>.capnp` " +
                  "and `<root>` is passed to capnp as an `--import-path`.",
        ),
        "_capnp_tool": attr.label(
            default = Label("@capnp-cpp//src/capnp:capnp_tool"),
            executable = True,
            cfg = "exec",
        ),
        "_shim": attr.label(
            default = "//bazel:capnpc_rust_shim",
            executable = True,
            cfg = "exec",
        ),
    },
)
