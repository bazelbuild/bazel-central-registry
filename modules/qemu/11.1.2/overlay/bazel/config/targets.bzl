"""Module extension computing the configuration of each emulator target.

For every target in //bazel/config:options.bzl this does what meson.build
does at configure time: merge configs/targets/<target>.mak with the
accelerators and default keys, and, for a system emulator, resolve the
device set with scripts/minikconf.py against the Kconfig tree.

The result is the repository @qemu_targets, whose targets.bzl holds

    TARGETS = {"x86_64-softmmu": {"TARGET_NAME": "x86_64", ...,
                                  "CONFIG_Q35": "y", ...}}

and version.bzl the contents of the VERSION file (QEMU_VERSION), which
BUILD files read to pick sources (qemu_target_library et al.) and to
write <target>-config-target.h / -config-devices.h.
"""

load("//bazel/config:config_host.bzl", "CONFIG_HOST")
load("//bazel/config:options.bzl", "OPTIONS")

# meson.build: disassemblers
_DISASSEMBLERS = {
    "alpha": ["CONFIG_ALPHA_DIS"],
    "avr": ["CONFIG_AVR_DIS"],
    "hexagon": ["CONFIG_HEXAGON_DIS"],
    "hppa": ["CONFIG_HPPA_DIS"],
    "i386": ["CONFIG_I386_DIS"],
    "x86_64": ["CONFIG_I386_DIS"],
    "m68k": ["CONFIG_M68K_DIS"],
    "microblaze": ["CONFIG_MICROBLAZE_DIS"],
    "mips": ["CONFIG_MIPS_DIS"],
    "or1k": ["CONFIG_OPENRISC_DIS"],
    "ppc": ["CONFIG_PPC_DIS"],
    "riscv": ["CONFIG_RISCV_DIS"],
    "rx": ["CONFIG_RX_DIS"],
    "s390": ["CONFIG_S390_DIS"],
    "sh4": ["CONFIG_SH4_DIS"],
    "sparc": ["CONFIG_SPARC_DIS"],
    "xtensa": ["CONFIG_XTENSA_DIS"],
    "loongarch": ["CONFIG_LOONGARCH_DIS"],
}

_HOST_ARCH = "x86_64"

# meson.build: host_kconfig, as far as this build supports the features.
def _host_kconfig(h):
    syms = []
    for sym, enabled in [
        ("CONFIG_TPM", h["CONFIG_TPM"]),
        ("CONFIG_PIXMAN", h["CONFIG_PIXMAN"]),
        ("CONFIG_SPICE", h["CONFIG_SPICE"]),
        ("CONFIG_IVSHMEM", h["CONFIG_EVENTFD"]),
        ("CONFIG_OPENGL", h["CONFIG_OPENGL"]),
        ("CONFIG_GNUTLS", h["CONFIG_GNUTLS"]),
        ("CONFIG_X11", h["CONFIG_X11"]),
        ("CONFIG_FDT", h["CONFIG_FDT"]),
        ("CONFIG_VHOST_USER", h["CONFIG_VHOST_USER"]),
        ("CONFIG_VHOST_VDPA", h["CONFIG_VHOST_VDPA"]),
        ("CONFIG_VHOST_KERNEL", h["CONFIG_VHOST_KERNEL"]),
        ("CONFIG_VIRTFS", h["CONFIG_VIRTFS"]),
        ("CONFIG_LINUX", h["CONFIG_LINUX"]),
        ("CONFIG_HAVE_RUST", h["CONFIG_HAVE_RUST"]),
    ]:
        if enabled:
            syms.append(sym + "=y")
    return syms

def _src(mctx, path):
    """A file of the source tree, by its path from the top."""
    return mctx.path(Label("//:" + path))

def _keyval(text):
    """configs/targets/*.mak and minikconf output: KEY=VALUE lines."""
    out = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        k, _, v = line.partition("=")
        out[k.strip()] = v.strip()
    return out

def _target_config(mctx, target, devmak, settings, python):
    name = target.split("-")[0]
    cfg = {"TARGET_NAME": name}
    if target.endswith("linux-user"):
        cfg["TARGET_ARCH_VARIANT"] = "TARGET_ARCH"
        cfg["CONFIG_LINUX_USER"] = "y"
        cfg["CONFIG_USER_ONLY"] = "y"

        # Defaults of meson_options.txt's interp_prefix and rtsig_map.
        cfg["CONFIG_QEMU_INTERP_PREFIX"] = "/usr/gnemul/qemu-" + name
        cfg["CONFIG_QEMU_RTSIG_MAP"] = "NULL"
    elif target.endswith("softmmu"):
        cfg["CONFIG_SYSTEM_ONLY"] = "y"
        cfg["CONFIG_SOFTMMU"] = "y"
    else:
        fail("unsupported target " + target)

    mak = _src(mctx, "configs/targets/" + target + ".mak")
    cfg.update(_keyval(mctx.read(mak)))

    kconfig = []
    for accelerator in settings["accelerators"]:
        sym = "CONFIG_" + accelerator.upper()
        cfg[sym] = "y"
        kconfig.append(sym + "=y")

    cfg["TARGET_" + cfg["TARGET_ARCH"].upper()] = "y"
    cfg.setdefault("TARGET_BASE_ARCH", cfg["TARGET_ARCH"])
    cfg.setdefault("TARGET_ABI_DIR", cfg["TARGET_ARCH"])
    cfg.setdefault("TARGET_BIG_ENDIAN", "n")
    for arch, syms in _DISASSEMBLERS.items():
        if _HOST_ARCH.startswith(arch) or cfg["TARGET_BASE_ARCH"].startswith(arch):
            for sym in syms:
                cfg[sym] = "y"

    if target.endswith("-softmmu"):
        kconfig.append("CONFIG_" + cfg["TARGET_ARCH"].upper() + "=y")
        kconfig.append("CONFIG_TARGET_BIG_ENDIAN=" + cfg["TARGET_BIG_ENDIAN"])
        kconfig_root = _src(mctx, "Kconfig")
        depfile = target + ".d"
        res = mctx.execute([
            python,
            _src(mctx, "scripts/minikconf.py"),
            "--defconfig" if settings["default_devices"] else "--allnoconfig",
            target + "-config-devices.mak",
            depfile,
            devmak,
            kconfig_root,
        ] + _host_kconfig(settings["config_host"]) + kconfig, environment = {
            "LC_ALL": "C",
            "PATH": "/nonexistent",
            "PYTHONDONTWRITEBYTECODE": "1",
            "PYTHONHASHSEED": "0",
        })
        if res.return_code:
            fail("minikconf failed for {}:\n{}".format(target, res.stderr))
        devs = _keyval(res.stdout)
        cfg.update(devs)
        cfg["DEVICES"] = sorted(devs.keys())

        # re-run when any Kconfig file minikconf read changes
        deps = mctx.read(depfile).replace("\\\n", " ").replace("\n", " ")
        for tok in deps.partition(":")[2].split(" "):
            if tok.startswith("/") and not tok.endswith(":"):
                mctx.watch(tok)
    return cfg

def _qemu_targets_repo_impl(rctx):
    rctx.file("BUILD.bazel", 'exports_files(["configuration.json"])\n')
    settings = json.decode(rctx.attr.settings)
    rctx.file("settings.bzl", "SETTINGS = " + repr(settings) + "\n")
    rctx.file("provenance.bzl", "SOURCE_PROVENANCE = " + repr(json.decode(rctx.attr.provenance)) + "\n")
    rctx.file("configuration.json", json.encode_indent(
        settings | {"targets": json.decode(rctx.attr.targets)},
        indent = "  ",
    ) + "\n")
    rctx.file("version.bzl", "QEMU_VERSION = {}\n".format(json.encode(rctx.attr.version)))

    # JSON sorts dictionary keys. Restore configure order for generators
    # such as gdbstub XML that consume the targets in order.
    rctx.file("targets.bzl", "_CONFIGS = " + json.encode_indent(
        json.decode(rctx.attr.targets),
        indent = "    ",
    ) + "\nTARGETS = {t: _CONFIGS[t] for t in " + repr(rctx.attr.order) + "}\n")

_qemu_targets_repo = repository_rule(
    implementation = _qemu_targets_repo_impl,
    attrs = {
        "order": attr.string_list(),
        "provenance": attr.string(),
        "settings": attr.string(),
        "targets": attr.string(),
        "version": attr.string(),
    },
)

def _qemu_targets_impl(mctx):
    if mctx.os.name != "linux" or mctx.os.arch not in ("amd64", "x86_64"):
        fail("QEMU repository configuration requires a Linux x86_64 host")
    python = mctx.path(Label("@qemu_host_python//:bin/python3"))
    tags = []
    for mod in mctx.modules:
        if mod.tags.configure and not mod.is_root:
            fail("only the root module may configure QEMU")
        tags.extend(mod.tags.configure)
    if len(tags) > 1:
        fail("QEMU accepts one configure tag per build")
    tag = tags[0] if tags else None
    profile = tag.profile if tag else "minimal"
    target = "x86_64-softmmu"
    default_devices = profile == "default"
    devmak = "default" if default_devices else "q35"
    devmak_path = _src(mctx, "configs/devices/{}/{}.mak".format(target, devmak))
    if tag and tag.devices:
        devmak_path = mctx.path(tag.devices)
    if tag and tag.device_mode:
        default_devices = tag.device_mode == "defconfig"
    accelerators = tag.accelerators if tag else ["kvm"]
    if accelerators != ["kvm"]:
        fail("the Linux x86_64 overlay currently supports exactly accelerators = [\"kvm\"]")
    backends = tag.trace_backends if tag else ["profile-default"]
    if backends == ["profile-default"]:
        backends = ["simple"] if profile == "default" else ["nop"]
    _check_choices("trace_backends", backends, ["simple", "log", "nop"])
    if not backends or ("nop" in backends and len(backends) != 1):
        fail("select at least one trace backend; nop must be used alone")
    features = tag.features if tag else ["profile-default"]
    if features == ["profile-default"]:
        features = ["pixman", "slirp"] if profile == "default" else []
    _check_choices("features", features, ["pixman", "slirp"])
    settings = {
        "accelerators": accelerators,
        "config_host": CONFIG_HOST | {
            "CONFIG_PIXMAN": "pixman" in features,
            "CONFIG_SLIRP": "slirp" in features,
            "CONFIG_TRACE_SIMPLE": "simple" in backends,
            "CONFIG_TRACE_LOG": "log" in backends,
        },
        "default_devices": default_devices,
        "device_set": str(tag.devices) if tag and tag.devices else devmak,
        "features": sorted(features),
        "options": OPTIONS | {k: k in features for k in ["pixman", "slirp"]},
        "profile": profile,
        "trace_backends": backends,
    }

    # These describe the corresponding Meson settings; Bazel does not run
    # configure. configuration.json also records the computed symbol sets.
    settings["configure_args"] = [
        "--target-list=" + target,
        "--without-default-features",
        "--enable-kvm",
        "--disable-tcg",
        "--disable-tools",
        "--disable-docs",
        "--disable-modules",
        "--disable-plugins",
        "--disable-rust",
        "--disable-gio",
    ] + ["--{}-{}".format("enable" if feature in features else "disable", feature) for feature in ["pixman", "slirp"]] + [
        "--disable-download",
        "--enable-trace-backends=" + ",".join(backends),
    ] + ([] if default_devices else ["--without-default-devices"])
    configs = {target: _target_config(mctx, target, devmak_path, settings, python)}
    version = mctx.read(_src(mctx, "VERSION")).strip()
    provenance = mctx.read(Label("//bazel:source_provenance.json"))
    if json.decode(provenance)["qemu_version"] != version:
        fail("source provenance does not match VERSION")
    _qemu_targets_repo(
        name = "qemu_targets",
        order = configs.keys(),
        provenance = provenance,
        settings = json.encode(settings),
        targets = json.encode(configs),
        version = version,
    )
    return mctx.extension_metadata(reproducible = True)

def _check_choices(field, values, allowed):
    if len({value: None for value in values}) != len(values) or any([value not in allowed for value in values]):
        fail("{} must contain unique choices from {}".format(field, allowed))

qemu_targets = module_extension(
    implementation = _qemu_targets_impl,
    tag_classes = {"configure": tag_class(attrs = {
        "accelerators": attr.string_list(default = ["kvm"]),
        "device_mode": attr.string(values = ["", "defconfig", "allnoconfig"]),
        "devices": attr.label(),
        "features": attr.string_list(default = ["profile-default"]),
        "profile": attr.string(default = "minimal", values = ["minimal", "default"]),
        "trace_backends": attr.string_list(default = ["profile-default"]),
    })},
)
