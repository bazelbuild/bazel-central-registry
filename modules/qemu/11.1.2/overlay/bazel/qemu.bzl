"""Macros for QEMU's BUILD files.

QEMU's meson.build collects sources into source sets (util_ss, block_ss,
system_ss, specific_ss, hw_arch['i386'], ...) with `ss.add(when: COND,
if_true: files(...), if_false: files(...))`, and applies them per target
configuration.  The macros here keep that shape so a BUILD file reads
like the meson.build next to it:

    qemu_source_set(
        name = "system_ss",
        kind = "system",
        srcs = ["always.c"],
        when = [
            when("CONFIG_SERIAL", ["serial.c"]),
            when("CONFIG_X86_IOMMU", ["x86-iommu.c"], if_false = ["x86-iommu-stub.c"]),
        ],
    )

A condition is a key, or a list of keys that must all hold; a key may be
negated ("!CONFIG_WIN32") or be a choice ("have_system|have_tools").  Keys
are looked up in, in this order:

  * the target configuration (@qemu_targets: configs/targets/*.mak, the
    accelerators and the Kconfig device selection), for keys a target
    defines;
  * CONFIG_HOST (config-host.h), for host features;
  * OPTIONS (//bazel/config:options.bzl), for build options.

Conditions that only involve the host and the options are decided when
the BUILD file is loaded.  Conditions on target keys are decided per
target: a `kind = "system"` / `"common"` source set compiles each such
group of sources once, as its own library, and gives every target a
`<name>_<target>` library that links the groups that target enables
(Meson's extract_objects()); a `qemu_target_source_set` compiles its
sources once per target, with that target's config-target.h.
"""

load("@qemu_targets//:settings.bzl", "SETTINGS")
load("@qemu_targets//:targets.bzl", "TARGETS")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

CONFIG_HOST = SETTINGS["config_host"]
OPTIONS = SETTINGS["options"]

# QEMU's common Linux x86_64 flags, limited to options shared by GCC and Clang.
QEMU_COPTS = [
    "-std=gnu11",
    "-O2",
    "-g0",
    "-UNDEBUG",
    "-mcx16",
    "-msse2",
    "-fno-strict-aliasing",
    "-fno-common",
    "-fwrapv",
    "-ftrivial-auto-var-init=zero",
    "-fzero-call-used-regs=used-gpr",
    "-Wall",
    "-Wempty-body",
    "-Wendif-labels",
    "-Wexpansion-to-defined",
    "-Wformat-security",
    "-Wformat-y2k",
    "-Wignored-qualifiers",
    "-Wimplicit-fallthrough",
    "-Wmissing-format-attribute",
    "-Wmissing-prototypes",
    "-Wnested-externs",
    "-Wold-style-definition",
    "-Wredundant-decls",
    "-Wshadow",
    "-Wstrict-prototypes",
    "-Wtype-limits",
    "-Wundef",
    "-Wvla",
    "-Wwrite-strings",
    "-Wno-missing-include-dirs",
    "-Wno-psabi",
    "-Wno-shift-negative-value",
]

# Link flags meson.build gives executables (b_asneeded, b_lundef and the
# relro/now hardening). Keep executable options in the module itself.
QEMU_LINKOPTS = [
    "-static",
    "-Wl,--no-undefined",
    "-Wl,-z,relro",
    "-Wl,-z,now",
    "-pthread",
]

QEMU_DEFINES = [
    "_GNU_SOURCE",
    "_FILE_OFFSET_BITS=64",
    "_LARGEFILE_SOURCE",
]

# What every QEMU compile sees: include/, the generated headers (config,
# QAPI, trace) and glib.
_QEMU_DEPS = ["//include:qemu"]

_SYSTEM_TARGETS = {t: c for t, c in TARGETS.items() if t.endswith("-softmmu")}

# Tags the libraries qemu_package() collects per target.
_TARGET_PART = "qemu_target_part"

# Extra defines per kind of source set (meson.build: libsystem, libuser).
_KIND_DEFINES = {
    "common": [],
    "system": ["CONFIG_SOFTMMU", "COMPILING_SYSTEM_VS_USER"],
}

def when(cond, if_true = [], if_false = []):
    """One `ss.add(when: cond, if_true: ..., if_false: ...)` entry."""
    conds = [cond] if type(cond) == "string" else list(cond)
    return struct(conds = conds, if_true = if_true, if_false = if_false)

def _lookup_one(key, target_config):
    if "=" in key:
        k, _, v = key.partition("=")
        return OPTIONS[k] == v
    if target_config != None and key in target_config:
        return target_config[key] not in ("n", "")
    if key in CONFIG_HOST:
        return CONFIG_HOST[key] not in (False, 0)
    if key in ("have_linux_user", "have_user"):
        return any([t.endswith("-linux-user") for t in TARGETS])
    if key in OPTIONS:
        return bool(OPTIONS[key])
    if key.startswith("CONFIG_") or key.startswith("TARGET_"):
        # strict: false, as in Meson: a symbol nobody defines is off
        return False
    fail("unknown condition '{}'".format(key))

def _lookup(key, target_config):
    """A key, "!key" or a choice "a|!b|..." of those."""
    for k in key.split("|"):
        negated = k.startswith("!")
        if _lookup_one(k.lstrip("!"), target_config) != negated:
            return True
    return False

def _is_target_key_one(key):
    return key not in CONFIG_HOST and key not in OPTIONS and "=" not in key and (
        key.startswith("CONFIG_") or key.startswith("TARGET_")
    )

def _is_target_key(key):
    """A key that only a target configuration can decide."""
    for k in key.split("|"):
        if _is_target_key_one(k.lstrip("!")):
            return True
    return False

def qemu_enabled(cond, target_config = None):
    """Whether a condition (a key or a list of keys) holds."""
    conds = [cond] if type(cond) == "string" else cond
    for c in conds:
        if not _lookup(c, target_config):
            return False
    return True

def qemu_select(entries, target_config = None):
    """The sources a list of when() entries contributes."""
    srcs = []
    for e in entries:
        for f in e.if_true if qemu_enabled(e.conds, target_config) else e.if_false:
            if f not in srcs:  # a source set holds each file once
                srcs.append(f)
    return srcs

def qemu_library(
        name,
        srcs = [],
        hdrs = [],
        textual_hdrs = [],
        deps = [],
        copts = [],
        local_defines = [],
        alwayslink = True,
        qemuutil = True,
        **kwargs):
    """A cc_library compiled the way meson.build compiles QEMU code.

    alwayslink defaults to True: QEMU links the objects of its libraries
    (extract_objects / declare_dependency(objects:)), and QOM types and
    modules register themselves from constructors nothing references.
    """
    implicit = _QEMU_DEPS + (["//:qemuutil"] if qemuutil else [])
    cc_library(
        name = name,
        srcs = srcs,
        hdrs = hdrs,
        textual_hdrs = textual_hdrs,
        deps = _unique_labels(deps + implicit),
        copts = QEMU_COPTS + copts,
        local_defines = QEMU_DEFINES + local_defines,
        alwayslink = alwayslink,
        **kwargs
    )

def _unique(items):
    """A list without repeats (a source set holds each file once)."""
    return {i: None for i in items}.keys()

def _unique_labels(labels):
    """Labels without repeats however they are spelled (":x", "//p:x")."""
    seen = {}
    for label in labels:
        seen.setdefault(str(native.package_relative_label(label)), label)
    return seen.values()

def _group_name(name, conds, negated):
    label = "_".join(conds).replace("!", "not_").replace("|", "_or_")
    return "{}_{}{}".format(name, "not_" if negated else "", label)

def qemu_source_set(
        name,
        srcs = [],
        when = [],
        kind = "common",
        hdrs = [],
        textual_hdrs = [],
        deps = [],
        copts = [],
        local_defines = [],
        visibility = None,
        **kwargs):
    """A target-independent source set (util_ss, block_ss, system_ss, ...).

    Everything is compiled once.  `:name` holds the unconditional sources
    and those whose conditions the host decides; each group of sources
    conditional on target keys becomes `:name_<COND>` (or
    `:name_not_<COND>` for if_false), and `:name_<target>` links `:name`
    with the groups that target enables.
    """
    defines = _KIND_DEFINES[kind] + local_defines
    common = dict(
        hdrs = hdrs,
        textual_hdrs = textual_hdrs,
        deps = deps,
        copts = copts,
        local_defines = defines,
        **kwargs
    )

    fixed = list(srcs)
    groups = {}  # library name -> (target conditions, negated, srcs)
    for e in when:
        target_conds = [c for c in e.conds if _is_target_key(c)]
        host_conds = [c for c in e.conds if not _is_target_key(c)]
        if not target_conds or not qemu_enabled(host_conds):
            fixed += qemu_select([e])
            continue
        for negated, files in [(False, e.if_true), (True, e.if_false)]:
            # only groups some configured target links are declared, so
            # that //... builds what the targets use, as ninja does
            if files and [t for t in _SYSTEM_TARGETS.values() if qemu_enabled(target_conds, t) != negated]:
                g = _group_name(name, target_conds, negated)
                groups.setdefault(g, (target_conds, negated, []))[2].extend(files)

    qemu_library(name = name, srcs = _unique(fixed), visibility = visibility, **common)
    for g, (_, _, files) in groups.items():
        qemu_library(name = g, srcs = _unique(files), visibility = ["//visibility:private"], **common)

    for target, config in _SYSTEM_TARGETS.items():
        cc_library(
            name = name + "_" + target,
            tags = [_TARGET_PART],
            deps = [":" + name] + [
                ":" + g
                for g, (conds, negated, _) in groups.items()
                if qemu_enabled(conds, config) != negated
            ],
            visibility = visibility,
        )

def qemu_user_source_set(name, srcs, when = [], deps = [], **kwargs):
    """A guest-independent part of Meson's libuser."""
    if qemu_enabled("have_linux_user"):
        qemu_library(
            name = name,
            srcs = srcs + qemu_select(when),
            local_defines = ["CONFIG_USER_ONLY", "COMPILING_SYSTEM_VS_USER"],
            deps = deps + ["//linux-user:common_headers"],
            **kwargs
        )

def qemu_archive_part(name, srcs = [], when = [], deps = [], visibility = None):
    """Sources that go into a library archive assembled elsewhere.

    libqemuutil.a is one archive of util_ss, stub_ss and trace_ss from many
    directories.  Its parts reference each other in both directions (a
    stub calls into util, util calls functions the stubs provide), which
    the linker resolves only inside one archive, so the parts are compiled
    together by qemu_archive() in the top-level package.  `:name` holds the
    sources and `:name_deps` what they need to compile.
    """
    native.filegroup(
        name = name,
        srcs = _unique(srcs + qemu_select(when)),
        visibility = visibility or ["//:__pkg__"],
    )
    cc_library(
        name = name + "_deps",
        deps = deps,
        visibility = visibility or ["//:__pkg__"],
    )

def qemu_archive(name, parts, deps = [], **kwargs):
    """One library (archive) from qemu_archive_part()s; see there."""
    qemu_library(
        name = name,
        srcs = parts,
        deps = deps,
        alwayslink = False,
        # Only the archive sources need the individual parts' private headers.
        implementation_deps = [p + "_deps" for p in parts],
        qemuutil = False,
        **kwargs
    )

def _qemu_common_arch_parts(name, targets, srcs, when, mode, local_defines, deps, visibility, kwargs):
    """Compile each selected source once for its base architecture."""
    arches = {}
    for target, config in targets.items():
        base = config["TARGET_BASE_ARCH"]
        arches.setdefault(base, {})[target] = _unique(srcs + qemu_select(when, config))

    defines = ["CPU_DEFS_H"] + (_KIND_DEFINES["system"] if mode == "system" else [])
    user_deps = ["//linux-user:common_headers"] if qemu_enabled("have_linux_user") else []
    for base, selections in arches.items():
        consumers = {}
        parts_by_target = {target: [] for target in selections}
        for target, files in selections.items():
            for src in files:
                consumers.setdefault(src, []).append(target)

        # Keep optional sources out of targets that did not select them,
        # without recompiling common sources when selections overlap.
        groups = {}
        for src, selected in consumers.items():
            groups.setdefault(tuple(selected), []).append(src)
        for i, (selected, files) in enumerate(groups.items()):
            part = "{}_{}_part{}".format(name, base, i)
            qemu_library(
                name = part,
                srcs = files,
                deps = deps + user_deps + ["//target/" + base + ":headers"],
                local_defines = defines + local_defines,
                visibility = ["//visibility:private"],
                **kwargs
            )
            for target in selected:
                parts_by_target[target].append(":" + part)
        for target, parts in parts_by_target.items():
            cc_library(
                name = name + "_" + target,
                deps = parts,
                tags = [_TARGET_PART],
                visibility = visibility,
            )

def qemu_target_source_set(
        name,
        srcs = [],
        when = [],
        arch = None,
        kind = "target",
        mode = "system",
        hdrs = [],
        textual_hdrs = [],
        deps = [],
        copts = [],
        local_defines = [],
        visibility = None,
        **kwargs):
    """A per-target source set (specific_ss, hw_arch, target_arch, ...).

    For each configured target (whose TARGET_BASE_ARCH is `arch`, when
    given) `:name_<target>` compiles the sources that target enables,
    with -DCONFIG_TARGET / -DCONFIG_DEVICES naming its configuration
    headers (the device header is system-only). Set mode to "user" or
    "both" for Linux-user or shared target-specific code, respectively.

    kind = "common_arch" is Meson's hw_common_arch, target_common_arch or
    target_common_system_arch: -DCPU_DEFS_H, without a target config
    header. A source is compiled once per base arch and linked only into
    the targets that select it. The default "system" mode adds the system
    defines; use "both" for architecture code shared by system and user.
    """
    if mode not in ("system", "user", "both"):
        fail("unknown compilation mode " + mode)
    targets = {
        target: config
        for target, config in TARGETS.items()
        if (mode == "both" or mode == ("system" if target in _SYSTEM_TARGETS else "user")) and
           (arch == None or config["TARGET_BASE_ARCH"] == arch)
    }
    if kind == "common_arch":
        _qemu_common_arch_parts(name, targets, srcs, when, mode, local_defines, deps, visibility, dict(
            hdrs = hdrs,
            textual_hdrs = textual_hdrs,
            copts = copts,
            **kwargs
        ))
        return
    if kind != "target":
        fail("unknown kind " + kind)
    for target, config in targets.items():
        system = target in _SYSTEM_TARGETS
        base = config["TARGET_BASE_ARCH"]
        user_deps = [] if system else [
            "//linux-user:headers",
            "//linux-user/{}:abi_headers".format(config["TARGET_ABI_DIR"]),
        ]
        qemu_library(
            name = name + "_" + target,
            srcs = _unique(srcs + qemu_select(when, config)),
            hdrs = hdrs,
            textual_hdrs = textual_hdrs,
            deps = deps + user_deps + ["//target/" + base + ":headers", "//:config_target_" + target],
            copts = copts,
            local_defines = [
                "COMPILING_PER_TARGET",
                'CONFIG_TARGET=\\"{}-config-target.h\\"'.format(target),
            ] + (
                ['CONFIG_DEVICES=\\"{}-config-devices.h\\"'.format(target)] if system else []
            ) + local_defines,
            visibility = visibility,
            tags = [_TARGET_PART],
            **kwargs
        )

def qemu_package(subdirs = []):
    """`:<target>`: what this directory and its subdirs give each target.

    Call it last in a BUILD file; `subdirs` are the meson.build's subdir()s.
    It links, per target, every library the macros above declared for that
    target in this package, and the same aggregate of each subdirectory.
    """
    pkg = native.package_name()
    for target in _SYSTEM_TARGETS:
        cc_library(
            name = target,
            deps = [
                ":" + r["name"]
                for r in native.existing_rules().values()
                if _TARGET_PART in r.get("tags", []) and r["name"].endswith("_" + target)
            ] + ["//{}:{}".format(pkg + "/" + s if pkg else s, target) for s in subdirs],
            visibility = ["//:__subpackages__"],
        )
