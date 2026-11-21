"""Trace event code generation (trace/meson.build)."""

load("@qemu_targets//:settings.bzl", "SETTINGS")
load(":python_gen.bzl", "python_gen")

# meson_options.txt: trace_backends
TRACE_BACKENDS = SETTINGS["trace_backends"]

def underscorify(s):
    """Meson's str.underscorify()."""
    return "".join([c if c.isalnum() else "_" for c in s.elems()])

def trace_events(group, src):
    """trace-<group>.h and trace-<group>.c from a trace-events file."""
    for fmt in ["h", "c"]:
        python_gen(
            name = "trace-{}_{}".format(group, fmt),
            src = src,
            deps = ["//scripts:tracetool_sources"],
            outs = ["trace-{}.{}".format(group, fmt)],
            arguments = [
                "--backend=" + ",".join(TRACE_BACKENDS),
                "--group=" + group,
                "--format=" + fmt,
                "{src}",
                "{out}",
            ],
            script = "//scripts:tracetool.py",
        )
