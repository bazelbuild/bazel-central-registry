"""`select()` helpers over the per-platform data of the targets.bzl files.

The module has no flag naming a target: the tools are built for whatever
platform the build is for, and every `cc_*` target picks its sources and
defines with a `select()` on the `@platforms` os/cpu pair.  `//:targets.bzl`
lists the pairs (PLATFORMS); each package's targets.bzl holds that
component's data keyed the same way, and the helpers here take those tables
as `(table,)` or, for bfd and ld, `(table, table_64)`, the twin being the
--enable-64-bit-bfd result.  A platform that is not in PLATFORMS, or that
upstream does not build a given program for, produces no matching
condition, which is the ordinary Bazel error for an unsupported
configuration.

The config settings these helpers name are declared in //:BUILD.bazel:

- `//:_platform_<key>`: the os/cpu pair of PLATFORMS[key].  PLATFORMS itself
  is a table too: `select_field((PLATFORMS,), "triple")`,
  `select_tool(PLATFORMS, "gprof")`.
- `//:_platform_<key>_bfd32` and `_bfd64`: the pair split by the
  `--enable-64-bit-bfd` flag, declared where PLATFORMS[key]["bfd64_differs"].
"""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")
load(":targets.bzl", "PLATFORMS")

visibility(["//..."])

# What `bazel build` reports when the target platform is not one of PLATFORMS.
NO_PLATFORM = "binutils is not configured for this target platform; the supported @platforms os/cpu pairs are listed in @binutils//:targets.bzl"

# For the programs only some platforms build (as/ld/gprof, the PE tools).
NO_PROGRAM = "binutils does not build this program for the target platform (see the top-level configure.ac and binutils/configure.tgt)"

def platform_setting(key):
    return "//:_platform_" + key

def _no_match(tables):
    """The error for a platform with no branch: a program table has None entries, a platform table does not."""
    return NO_PROGRAM if None in tables[0].values() else NO_PLATFORM

def _variants(key, tables):
    """(config setting, data) pairs of platform KEY in TABLES.

    Args:
        key: a PLATFORMS key.
        tables: `(table,)`, or `(table, table_64)` for bfd and ld.

    Returns:
        One pair, or two under the `_bfd32`/`_bfd64` settings where
        --enable-64-bit-bfd changes the platform's bfd; none where the
        platform does not build the component.
    """
    data = tables[0][key]
    if data == None:
        return []
    if len(tables) == 2 and PLATFORMS[key]["bfd64_differs"]:
        return [
            (platform_setting(key) + "_bfd32", data),
            (platform_setting(key) + "_bfd64", tables[1][key]),
        ]
    return [(platform_setting(key), data)]

def select_field(tables, field):
    """A select() yielding TABLES[*][FIELD] per platform.

    Args:
        tables: the component table(s), see _variants.
        field: the key within the component's dict.

    Returns:
        A select() with one branch per platform that builds the component.
    """
    branches = {}
    for key in PLATFORMS:
        for setting, data in _variants(key, tables):
            branches[setting] = data[field]
    return select(branches, no_match_error = _no_match(tables))

def select_flag_defines(flags, if_false = "0"):
    """AC_DEFINE(NAME, 1) under each boolean flag, else AC_DEFINE(NAME, IF_FALSE).

    Args:
        flags: list of (flag, define) pairs; the flag's `//:_<flag>` setting
            is true when the bool_flag is.
        if_false: the value defined when the flag is off; None defines
            nothing then (an `#undef` in config.h).

    Returns:
        The concatenated select()s, for an `autoconf` target's checks.
    """
    result = []
    for flag, define in flags:
        result += select({
            "//:_" + flag: [checks.AC_DEFINE(define, "1")],
            "//conditions:default": [checks.AC_DEFINE(define, if_false)] if if_false != None else [],
        })
    return result

def select_default(tables, field):
    """The target's default for a yes/no/auto option, as the string `policy_defines` keys on.

    Args:
        tables: the component table(s) whose `defaults` carry the answer.
        field: the key under `defaults`.

    Returns:
        A select() of `str(default)` per platform that builds the component.
    """
    branches = {}
    for key in PLATFORMS:
        for setting, data in _variants(key, tables):
            branches[setting] = str(data["defaults"][field])
    return select(branches, no_match_error = _no_match(tables))

def select_triple():
    """The canonical triple of the platform, as configure's $target."""
    return select_field((PLATFORMS,), "triple")

def select_gas_header(gas, name):
    """The one-line `#include` of gas indirection header NAME (gas/configure.ac:1047-1057).

    Args:
        gas: the GAS table.
        name: "targ-cpu.h", "obj-format.h", "targ-env.h" or "itbl-cpu.h".

    Returns:
        A select() of write_file content, per platform that builds gas.
    """
    included = {
        "itbl-cpu.h": "itbl-{cpu_type}.h",
        "obj-format.h": "obj-{obj_format}.h",
        "targ-cpu.h": "tc-{cpu_type}.h",
        "targ-env.h": "te-{em}.h",
    }[name]
    return select({
        platform_setting(key): ['#include "{}"'.format(included.format(cpu_type = data["cpu_type"], obj_format = data["obj_format"], em = data["em"]))]
        for key, data in gas.items()
        if data != None
    }, no_match_error = _no_match((gas,)))

def select_ldemul_list(tables):
    """The ldemul-list.h content (ld/Makefile.am:366-379).

    Args:
        tables: `(LD, LD_64)`.

    Returns:
        A select() of write_file content, per platform that builds ld.
    """
    branches = {}
    for key in PLATFORMS:
        for setting, data in _variants(key, tables):
            names = ["ld_{}_emulation".format(e) for e in data["emulations"]]
            branches[setting] = (
                ["/* This file is automatically generated.  DO NOT EDIT! */"] +
                ["extern ld_emulation_xfer_type {};".format(n) for n in names] +
                ["", "#define EMULATION_LIST \\"] +
                ["  &{}, \\".format(n) for n in names] +
                ["  0"]
            )
    return select(branches, no_match_error = _no_match(tables))

def select_tdefaults_wrapper(tables, source):
    """A wrapper that defines $(TDEFAULTS) and includes SOURCE (bfd/Makefile.am:782-806).

    Args:
        tables: `(BFD, BFD_64)`.
        source: "targets.c" or "archures.c".

    Returns:
        A select() of write_file content, per platform.
    """
    branches = {}
    for key in PLATFORMS:
        for setting, data in _variants(key, tables):
            branches[setting] = [
                "#define " + define.replace("=", " ", 1)
                for define in data["tdefaults"]
            ] + ['#include "{}"'.format(source)]
    return select(branches, no_match_error = _no_match(tables))

def select_bfd_substs(tables):
    """The bfd.h placeholders the configuration decides (bfd/configure.ac:790-803).

    Args:
        tables: `(BFD, BFD_64)`.

    Returns:
        A select() of AC_SUBST checks for wordsize and bfd_default_target_size.
    """
    branches = {}
    for key in PLATFORMS:
        for setting, data in _variants(key, tables):
            branches[setting] = [
                checks.AC_SUBST("wordsize", data["wordsize"]),
                checks.AC_SUBST("bfd_default_target_size", data["default_target_size"]),
            ]
    return select(branches, no_match_error = _no_match(tables))

def select_bfd_elf(bfd):
    """HAVE_BFD_ELF for libctf: whether libbfd carries the ELF backend (libctf/configure.ac:84-101).

    Args:
        bfd: the BFD table.

    Returns:
        A select() of a define list, per platform.
    """
    return select({
        platform_setting(key): ["HAVE_BFD_ELF=1"] if "elf.c" in data["srcs"] else []
        for key, data in bfd.items()
    }, no_match_error = _no_match((bfd,)))

def select_tool(table, field):
    """An empty list where TABLE[*][FIELD] is true; no branch elsewhere.

    For the programs only some platforms build: adding this to a target's
    `srcs` makes the target unconfigurable, with the ordinary no-matching-
    condition error, everywhere else.

    Args:
        table: a component table.
        field: a boolean key within the component's dict.

    Returns:
        A select() with an empty-list branch per platform where FIELD is true.
    """
    return select({platform_setting(key): [] for key, data in table.items() if data != None and data[field]}, no_match_error = NO_PROGRAM)
