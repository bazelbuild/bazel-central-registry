# Building NVC with Bazel

This directory contains the support files for building NVC with
[Bazel](https://bazel.build) instead of the autotools build.  It is a fully
native Bazel build: it does **not** use `rules_foreign_cc`, and every
dependency is a module published on the
[Bazel Central Registry](https://registry.bazel.build) (BCR).  The build
targets Bazel 9.1.0 (see `.bazelversion`).

## What is built

The build configures NVC the same way as `./configure --disable-llvm`: the
LLVM code generator is left out and NVC's built-in interpreter plus x86-64 JIT
back end are used instead.  This keeps the dependency set to a handful of small
BCR modules (zlib, zstd, libffi and the flex toolchain).

| Target          | Description                                                  |
|-----------------|--------------------------------------------------------------|
| `//:nvc`        | The `nvc` compiler / simulator executable.                   |
| `//:std`        | The bootstrapped VHDL standard libraries (a directory tree). |
| `//:nvc_cmd`    | Convenience launcher that runs `nvc` with `NVC_LIBPATH` set. |
| `//:libnvc`     | The compiler as a `cc_library` (for embedding).              |

## Usage

```sh
# Build the compiler and the standard libraries.
bazel build //:nvc //:std

# Run a design through analyse / elaborate / run using the launcher, which
# points NVC at the bootstrapped libraries automatically.
bazel run //:nvc_cmd -- -a my_design.vhd my_tb.vhd -e my_tb -r
```

To use the raw `//:nvc` binary directly, point `NVC_LIBPATH` at the generated
library tree:

```sh
NVC_LIBPATH="$(bazel info bazel-bin)/stdlib" \
    "$(bazel info bazel-bin)/nvc" -a my_design.vhd -e my_tb -r
```

## How the standard libraries are bootstrapped

NVC compiles its own VHDL standard libraries: the freshly built `nvc` binary is
run over the sources under `lib/` to produce the runtime library tree.  The
analysis order matters, and the full dependency graph is already recorded in
the checked-in `lib/*/deps.mk` manifests.  `bazel/bootstrap.bash` parses those
manifests, topologically sorts the analysis units with `tsort(1)`, and runs
`nvc -a` once per source file (driven by the `nvc_bootstrap` rule in
`bazel/bootstrap.bzl`).

## Files

| File                     | Purpose                                                  |
|--------------------------|----------------------------------------------------------|
| `config.h`               | Fixed replacement for the configure-generated header.    |
| `bootstrap.bzl`          | The `nvc_bootstrap` rule.                                |
| `bootstrap.bash`         | Topologically-ordered standard library build script.     |
| `gen_cov_style.sh`       | Embeds the coverage stylesheet as a C string.            |
| `nvc_wrapper.sh`         | `bazel run //:nvc_cmd` launcher.                         |

## Limitations

* Linux on x86-64 (glibc) is the tested configuration.  `config.h` is written
  for that platform; aarch64 needs the NEON paths enabled there.
* The LLVM code generator, the TCL shell, capstone disassembly and the
  libcheck unit-test suite are not built.
