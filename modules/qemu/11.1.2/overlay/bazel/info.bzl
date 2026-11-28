"""QEMU build facts for downstream rules. The manifest is the execution receipt."""

load("@qemu_targets//:provenance.bzl", "SOURCE_PROVENANCE")
load("@qemu_targets//:version.bzl", "QEMU_VERSION")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_python//python:py_runtime_info.bzl", "PyRuntimeInfo")

QemuBuildInfo = provider(fields = {
    "version": "QEMU release version.",
    "provenance": "Verified materialization metadata (unpatched for the registry release).",
    "configuration": "Canonical configuration JSON File.",
    "toolchain": "Selected C/C++ toolchain metadata.",
    "elf": "Linked ELF File.",
    "manifest": "JSON File containing the ELF hash, runtime audit, and all build facts.",
})

def _impl(ctx):
    cc = find_cc_toolchain(ctx)
    libc = cc.libc

    # Some toolchains, including Zig, encode libc in their ID instead of
    # setting the generic CcToolchainInfo.libc field.
    if libc in ("", "unknown"):
        target = cc.toolchain_id.removesuffix("-toolchain").split("-")
        if len(target) == 3 and target[1] == "linux":
            if target[2] == "musl":
                libc = "musl"
            elif target[2].startswith("gnu"):
                libc = "glibc" + target[2].removeprefix("gnu")
    toolchain = {
        "id": cc.toolchain_id,
        "compiler": cc.compiler,
        "cpu": cc.cpu,
        "libc": libc,
        "target": cc.target_gnu_system_name,
    }
    runtime = ctx.attr._python[PyRuntimeInfo]
    if runtime.interpreter == None:
        fail("QEMU provenance requires the file-backed Python runtime")
    manifest = ctx.actions.declare_file(ctx.label.name + ".manifest.json")
    elf = ctx.executable.binary
    configuration = ctx.file._configuration
    ctx.actions.run(
        executable = runtime.interpreter,
        arguments = [
            ctx.file._script.path,
            elf.path,
            configuration.path,
            manifest.path,
            json.encode(SOURCE_PROVENANCE),
            json.encode(toolchain),
        ],
        inputs = depset([elf, configuration, ctx.file._script], transitive = [runtime.files]),
        outputs = [manifest],
        env = {"LC_ALL": "C", "PATH": "/nonexistent", "PYTHONHASHSEED": "0"},
        mnemonic = "QemuBuildManifest",
    )
    return [
        DefaultInfo(files = depset([manifest])),
        OutputGroupInfo(elf = depset([elf]), configuration = depset([configuration])),
        QemuBuildInfo(
            version = QEMU_VERSION,
            provenance = SOURCE_PROVENANCE,
            configuration = configuration,
            toolchain = toolchain,
            elf = elf,
            manifest = manifest,
        ),
    ]

qemu_build_info = rule(
    implementation = _impl,
    attrs = {
        "binary": attr.label(executable = True, cfg = "target", mandatory = True),
        "_configuration": attr.label(default = Label("@qemu_targets//:configuration.json"), allow_single_file = True),
        "_python": attr.label(default = Label("@python_3_12//:py3_runtime"), providers = [PyRuntimeInfo], cfg = "exec"),
        "_script": attr.label(default = Label("//bazel:build_manifest.py"), allow_single_file = True),
    },
    toolchains = use_cc_toolchain(),
)
