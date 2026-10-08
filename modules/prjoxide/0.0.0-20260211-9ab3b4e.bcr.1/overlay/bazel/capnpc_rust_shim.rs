//! Bazel-side shim around `capnpc::CompilerCommand` that produces the same
//! `OUT_DIR` layout the upstream `build.rs` does, so the unmodified
//! `src/schema.rs` (`include!(concat!(env!("OUT_DIR"), "/<X>_capnp.rs"))`)
//! works against Bazel-generated files.
//!
//! Usage:
//!   capnpc_rust_shim \
//!     --capnp <path-to-capnp-binary> \
//!     --out-dir <OUT_DIR> \
//!     --src-prefix <prefix-stripped-from-srcs> \
//!     --parent-module <dotted::path> \
//!     -- <file.capnp>...

use std::env;
use std::path::PathBuf;
use std::process::ExitCode;

fn fail(msg: &str) -> ! {
    eprintln!("capnpc_rust_shim: {msg}");
    std::process::exit(2);
}

fn main() -> ExitCode {
    let mut capnp: Option<PathBuf> = None;
    let mut out_dir: Option<PathBuf> = None;
    let mut src_prefix: Option<String> = None;
    let mut parent_module: Vec<String> = Vec::new();
    let mut import_paths: Vec<PathBuf> = Vec::new();
    let mut files: Vec<PathBuf> = Vec::new();
    let mut args = env::args().skip(1);
    let mut positional = false;
    while let Some(arg) = args.next() {
        if positional {
            files.push(PathBuf::from(arg));
            continue;
        }
        match arg.as_str() {
            "--" => positional = true,
            "--capnp" => capnp = Some(PathBuf::from(args.next().unwrap_or_else(|| fail("--capnp needs a value")))),
            "--out-dir" => out_dir = Some(PathBuf::from(args.next().unwrap_or_else(|| fail("--out-dir needs a value")))),
            "--src-prefix" => src_prefix = Some(args.next().unwrap_or_else(|| fail("--src-prefix needs a value"))),
            "--parent-module" => parent_module = args
                .next()
                .unwrap_or_else(|| fail("--parent-module needs a value"))
                .split("::")
                .map(|s| s.to_string())
                .collect(),
            "--import-path" => import_paths.push(PathBuf::from(
                args.next().unwrap_or_else(|| fail("--import-path needs a value")),
            )),
            other => fail(&format!("unexpected argument: {other}")),
        }
    }
    let capnp = capnp.unwrap_or_else(|| fail("--capnp <path> is required"));
    let out_dir = out_dir.unwrap_or_else(|| fail("--out-dir <path> is required"));
    if files.is_empty() {
        fail("at least one .capnp source file is required after `--`");
    }

    // capnpc::CompilerCommand picks OUT_DIR from the env var by default; we
    // set it explicitly here so the shim works regardless of how Bazel set
    // up the action's environment.
    env::set_var("OUT_DIR", &out_dir);
    if let Err(e) = std::fs::create_dir_all(&out_dir) {
        fail(&format!("failed to create {}: {e}", out_dir.display()));
    }

    let mut cmd = capnpc::CompilerCommand::new();
    cmd.capnp_executable(&capnp);
    cmd.output_path(&out_dir);
    if let Some(prefix) = src_prefix {
        cmd.src_prefix(prefix);
    }
    if !parent_module.is_empty() {
        cmd.default_parent_module(parent_module);
    }
    for p in &import_paths {
        cmd.import_path(p);
    }
    for f in &files {
        cmd.file(f);
    }

    if let Err(e) = cmd.run() {
        eprintln!("capnpc_rust_shim: capnp compile failed: {e}");
        return ExitCode::from(1);
    }
    ExitCode::SUCCESS
}
