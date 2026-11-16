"""Build the Linux audit lookup tables with the upstream generator."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

def audit_table(name, tool, table, arguments):
    cc_binary(
        name = "gen_" + name,
        srcs = [
            "config.h",
            "gcc-attributes.h",
            "auparse/auparse-defs.h",
            "lib/" + table,
            "lib/" + tool + ".c",
            "lib/" + tool + ".h",
            "lib/audit-records.h",
            "lib/audit_logging.h",
            "lib/libaudit.h",
        ],
        includes = ["auparse", "lib"],
        local_defines = ["TABLE_H=<%s>" % table],
    )
    native.genrule(
        name = name,
        outs = [name + ".h"],
        cmd = "$(execpath :gen_" + name + ") " + arguments + " > $@",
        tools = [":gen_" + name],
    )
