"""One firmware platform's targets from its data: the probed flags, the
configured config.h, the include trees and the compile targets.

`grub_platform` is a BUILD-file helper, not a rule: everything it declares is
an `autoconf`, `autoconf_hdr`, `write_file`, `expand_template` or
`cc_library`.  The compile targets are the part of the boot image build that
is only "these files with these flags"; linking, stripping, the `*.lst` files
and genmod stay with the rule set that consumes the objects.
"""

load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc_autoconf//autoconf:autoconf.bzl", "autoconf")
load("@rules_cc_autoconf//autoconf:autoconf_hdr.bzl", "autoconf_hdr")
load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")
load(":common.bzl", "COMMON")

visibility("private")

_KINDS = ["cflags", "ccasflags", "cppflags", "ldflags"]

# The automake conditionals of Makefile.core.def, as the root package's
# settings; a module under any other condition is left out of `_objects`.
_CONDITIONS = {
    "COND_ENABLE_BOOT_TIME_STATS": "//:boot_time",
    "COND_ENABLE_CACHE_STATS": "//:cache_stats",
    "COND_MM_DEBUG": "//:mm_debug",
}

# CPPFLAGS_DEFAULT's `-I`s (conf/Makefile.common), before a module's own.
_DEFAULT_INCLUDE_DIRS = ["grub-core", "include", "grub-core/lib/libgcrypt-grub/src"]

def _piece(prefix, kind, step, i):
    """The AC_SUBST a step's candidate contributes to one flag kind (or config.h value)."""
    return "GRUB_{}_{}_{}_{}".format(prefix.upper(), kind.upper(), step.upper(), i)

def _check(prefix, step, i):
    return "grub_cv_{}_{}_{}".format(prefix, step, i)

def _when(prefix, data, when):
    """A step's `when` (`clang`, `pie`, `!clang`): that probe hit, or missed.

    A hit is the check passing, or failing for a `negate` probe.
    """
    if not when:
        return None
    probe = when.lstrip("!")
    negate = [s for s in data["steps"] if s.get("probe") == probe][0].get("negate", False)
    return ("!" if when.startswith("!") != negate else "") + _check(prefix, probe, 0)

def _step_name(step, n):
    return step["probe"] if "probe" in step else "literal_{}".format(n)

def _contributions_of(prefix, name, i, to, condition):
    out = []
    for kind, flags in to.items():
        if kind == "subst":
            for var, value in flags.items():
                out.append(struct(kind = "subst", var = var, step = name, piece = _piece(prefix, var, name, i), condition = condition, value = value))
        else:
            out.append(struct(kind = kind, var = None, step = name, piece = _piece(prefix, kind, name, i), condition = condition, value = " ".join(flags)))
    return out

def _contributions(prefix, data):
    """Every (kind, piece name, condition, value) the steps produce.

    A probe tries its candidates in order; the first whose program compiles
    contributes its flags, as configure's `for cand in ...` loops do.
    `negate` probes hit when the program fails (`#error` under `__PIE__`).
    Unconditional literal flags go into the templates verbatim and are not
    contributions; literal config.h values are.
    """
    out = []
    for n, step in enumerate(data["steps"]):
        name = _step_name(step, n)
        when = _when(prefix, data, step.get("when"))
        if "literal" in step:
            if when or "subst" in step["literal"]:
                out += _contributions_of(prefix, name, 0, step["literal"], when)
            continue
        missed = []
        for i, cand in enumerate(step["candidates"]):
            check = _check(prefix, name, i)
            this = ("!" if step.get("negate") else "") + check
            out += _contributions_of(prefix, name, i, cand["to"], " && ".join(missed + [this] + ([when] if when else [])))
            missed.append(("" if step.get("negate") else "!") + check)
        if "otherwise" in step:
            out += _contributions_of(prefix, name, 99, step["otherwise"], " && ".join(missed + ([when] if when else [])))
    return out

def _checks(prefix, data, contributions):
    """The autoconf checks: configure's probes, then one AC_SUBST per contribution."""
    out = []
    base = data["literal_flags"]["cflags"] + data["literal_flags"]["cppflags"]
    for n, step in enumerate(data["steps"]):
        if "literal" in step:
            continue
        name = _step_name(step, n)
        when = _when(prefix, data, step.get("when"))
        missed = []
        for i, cand in enumerate(step["candidates"]):
            check = _check(prefix, name, i)
            out.append(checks.AC_TRY_COMPILE(
                name = check,
                code = step["code"],
                copts = base + step.get("copts", []) + cand["flags"] + ["-Werror"],
                requires = missed + ([when] if when else []),
            ))
            missed.append(("" if step.get("negate") else "!") + check)
    for c in contributions:
        if c.condition:
            out.append(checks.AC_SUBST(c.piece, condition = c.condition, if_true = c.value, if_false = ""))
        else:
            out.append(checks.AC_SUBST(c.piece, value = c.value))
    return out

def _response_lines(kind, data, contributions):
    """A response file template in configure's order: literal flags verbatim, a placeholder per probe contribution."""
    out = []
    for n, step in enumerate(data["steps"]):
        name = _step_name(step, n)
        if "literal" in step and "when" not in step:
            out += step["literal"].get(kind, [])
        else:
            out += ["@{}@".format(c.piece) for c in contributions if c.kind == kind and c.step == name]
    return out

def _config_substitutions(contributions):
    """config.h.in's probed values as the concatenation of their pieces (at most one is non-empty)."""
    out = {}
    for c in contributions:
        if c.kind == "subst":
            out["@{}@".format(c.var)] = out.get("@{}@".format(c.var), "") + "@{}@".format(c.piece)
    return out

def _include(dir):
    """`-I` on a repository-relative source directory."""
    root = Label("//:BUILD.bazel").workspace_root
    return "-I" + (root + "/" + dir if root else dir)

def _library(name, srcs, data, prefix, entry, class_flags, asm, deps, tags):
    """A cc_library of one def entry's C (or assembly) sources with the platform's flags.

    The include directories are the source tree's, in CPPFLAGS_DEFAULT's order
    and then the entry's own, with every header of the tree as an input;
    strip_include_prefix trees would break the relative includes libgcrypt's
    headers make.
    """
    rsp = lambda kind: "@$(execpath :{}_{}_rsp)".format(prefix, kind)
    pic = ["-fno-PIC"]
    if data["target_cpu"] in ("arm64", "mips", "mipsel"):
        pic = select({
            "@rules_cc//cc/compiler:clang": ["-fPIC"],
            "//conditions:default": ["-fno-PIC"],
        })
    defines = [d[2:] for d in entry.get("cppflags", []) if d.startswith("-D")]
    other = [d for d in entry.get("cppflags", []) if not d.startswith("-D")]
    includes = [_include(d) for d in _DEFAULT_INCLUDE_DIRS + entry.get("include_dirs", [])]
    kwargs = {}
    if asm:
        copts = [rsp("ccasflags"), rsp("cppflags"), "-DASM_FILE=1"] + entry.get("ccasflags", []) + other + includes
    else:
        copts = [rsp("cppflags")] + other + includes

        # Bazel's toolchains compile libraries PIC; configure turns that off
        # (grub_CHECK_PIC), except for clang on arm64 and mips.
        kwargs["conlyopts"] = [rsp("cflags")] + class_flags + data["cflags_platform"] + entry.get("cflags", []) + pic
    nodist_srcs = ["//:" + COMMON["nodist"][n] for n in entry.get("nodist", []) if n in COMMON["nodist"] and n.endswith(".c")]
    if [n for n in entry.get("nodist", []) if n in COMMON["nodist"] and n.endswith(".h")]:
        deps = deps + ["//:grub_script_hdrs"]
    cc_library(
        name = name,
        srcs = srcs + entry.get("extra_inputs", []) + nodist_srcs + ["//:core_hdrs"],
        additional_compiler_inputs = [":{}_{}_rsp".format(prefix, kind) for kind in _KINDS],
        copts = copts,
        linkstatic = True,
        local_defines = COMMON["cppflags_default_defines"] + ["GRUB_FILE=__FILE__"] + defines,
        tags = tags,
        textual_hdrs = ["//:core_textual_srcs"],
        deps = deps,
        **kwargs
    )

def _libraries(name, data, prefix, entry, class_flags, deps, tags):
    """The C and, when the entry has `.S` sources, the assembly library of a def entry.

    Returns the targets, or nothing when the entry needs a generated source
    only a rule set makes (lzma_decompress's rs_decoder.h).
    """
    if [n for n in entry.get("nodist", []) if n not in COMMON["nodist"] and n.endswith(".h")]:
        return []
    srcs = entry.get("startup", []) + entry.get("srcs", [])
    c_srcs = [s for s in srcs if not str(s).endswith(".S")]
    s_srcs = [s for s in srcs if str(s).endswith(".S")]
    out = []
    if c_srcs:
        _library(name, c_srcs, data, prefix, entry, class_flags, False, deps, tags)
        out.append(":" + name)
    if s_srcs:
        _library(name + "_asm", s_srcs, data, prefix, entry, class_flags, True, deps, tags)
        out.append(":" + name + "_asm")
    return out

def grub_platform(name, data):
    """Declares one platform's targets.

    Args:
      name: The platform, as gentpl.py and `PLATFORM_DATA` name it (`i386_pc`).
      data: Its dict from `<platform>.bzl`.

    Targets (all `manual`, since they compile for the platform's CPU):
    `<name>_flags` (the probes), `<name>_{cflags,ccasflags,cppflags,ldflags}_rsp`
    (TARGET_* as response files), `<name>_config_h` and `<name>_config`,
    `<name>_cpu_hdrs`/`<name>_machine_hdrs` (include/grub/cpu and machine),
    `<name>/kernel`, `<name>/mod/<module>`, `<name>/image/<image>` (`_asm`
    variants for `.S` sources) and `<name>_objects` naming them all.
    """
    tags = ["manual"]
    contributions = _contributions(name, data)

    autoconf(
        name = name + "_flags",
        checks = _checks(name, data, contributions),
        tags = tags,
    )
    for kind in _KINDS:
        write_file(
            name = "{}_{}_rsp_in".format(name, kind),
            out = "{}/{}.rsp.in".format(name, kind),
            content = _response_lines(kind, data, contributions) + [""],
            tags = tags,
        )
        autoconf_hdr(
            name = "{}_{}_rsp".format(name, kind),
            out = "{}/{}.rsp".format(name, kind),
            mode = "subst",
            template = ":{}_{}_rsp_in".format(name, kind),
            tags = tags,
            deps = [":" + name + "_flags"],
        )

    # AC_CONFIG_FILES([config.h]): the kernel arm of config.h.in.  The package
    # names come from //:package through //:autoconf as quoted C strings, so
    # the quotes the template puts around those placeholders are taken off.
    expand_template(
        name = name + "_config_h_in",
        out = name + "/config.h.in",
        substitutions = {
            "\"@PACKAGE@\"": "@PACKAGE@",
            "\"@PACKAGE_BUGREPORT@\"": "@PACKAGE_BUGREPORT@",
            "\"@PACKAGE_NAME@\"": "@PACKAGE_NAME@",
            "\"@PACKAGE_STRING@\"": "@PACKAGE_STRING@",
            "\"@PACKAGE_VERSION@\"": "@PACKAGE_VERSION@",
            "\"@VERSION@\"": "@VERSION@",
            "@GRUB_PLATFORM@": data["platform"],
            "@GRUB_STACK_PROTECTOR_INIT@": "",
            "@GRUB_TARGET_CPU@": data["target_cpu"] or "",
        } | _config_substitutions(contributions),
        tags = tags,
        template = "//:config.h.in",
    )
    autoconf_hdr(
        name = name + "_config_h",
        out = name + "/config.h",
        mode = "subst",
        tags = tags,
        template = ":" + name + "_config_h_in",
        deps = [
            ":" + name + "_flags",
            "//:autoconf",
        ],
    )
    cc_library(
        name = name + "_config",
        hdrs = [":" + name + "_config_h"],
        strip_include_prefix = name,
        tags = tags,
    )

    # AC_CONFIG_LINKS: include/grub/cpu and include/grub/machine.
    deps = [":" + name + "_config"]
    for sub, dir, hdrs in [("cpu", data["cpu_dir"], data["cpu_hdrs"]), ("machine", data["machine_dir"], data["machine_hdrs"])]:
        if hdrs:
            cc_library(
                name = "{}_{}_hdrs".format(name, sub),
                hdrs = hdrs,
                include_prefix = "grub/" + sub,
                strip_include_prefix = "/" + dir,
                tags = tags,
            )
            deps.append(":{}_{}_hdrs".format(name, sub))

    objects = []
    conditional = {}
    if data["kernel"]:
        objects += _libraries(name + "/kernel", data, name, data["kernel"], COMMON["cflags_kernel"] + ["-DGRUB_KERNEL=1"], deps, tags)
    for module, entry in data["modules"].items():
        libs = _libraries("{}/mod/{}".format(name, module), data, name, entry, COMMON["cflags_module"], deps, tags)
        if "condition" not in entry:
            objects += libs
        elif entry["condition"] in _CONDITIONS:
            conditional[_CONDITIONS[entry["condition"]]] = conditional.get(_CONDITIONS[entry["condition"]], []) + libs
    for image, entry in data["images"].items():
        objects += _libraries("{}/image/{}".format(name, image), data, name, entry, COMMON["cflags_image"], deps, tags)
    for setting, libs in conditional.items():
        objects += select({setting: libs, "//conditions:default": []})
    native.filegroup(
        name = name + "_objects",
        srcs = objects,
        tags = tags,
    )

    # Every file the platform's kernel, modules and images compile or include.
    native.filegroup(
        name = name + "_srcs",
        srcs = {
            label: None
            for entry in [{"srcs": data["kernel_headers"]}, data["kernel"]] + data["modules"].values() + data["images"].values()
            if entry
            for label in entry.get("startup", []) + entry.get("srcs", []) + entry.get("extra_inputs", [])
        }.keys(),
    )
