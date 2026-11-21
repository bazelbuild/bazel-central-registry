"""The QAPI schema modules and what qapi-gen.py writes for them
(qapi/meson.build)."""

load("//bazel:qemu.bzl", "qemu_enabled")

QAPI_ALL_MODULES = [
    "authz",
    "block",
    "block-core",
    "block-export",
    "char",
    "common",
    "compat",
    "control",
    "crypto",
    "cxl",
    "dump",
    "ebpf",
    "error",
    "introspect",
    "job",
    "machine-common",
    "machine",
    "machine-s390x",
    "migration",
    "misc",
    "net",
    "pragma",
    "qom",
    "replay",
    "run-state",
    "sockets",
    "stats",
    "trace",
    "transaction",
    "vfio",
    "virtio",
    "yank",
] + ([
    "accelerator",
    "acpi",
    "acpi-hest",
    "audio",
    "cryptodev",
    "qdev",
    "pci",
    "rocker",
    "misc-arm",
    "misc-i386",
    "tpm",
    "uefi",
] if qemu_enabled("have_system") else []) + (
    ["ui"] if qemu_enabled("have_system|have_tools") else []
)

_WITH_COMMANDS = qemu_enabled("have_system|have_tools")

QAPI_NONMODULE_OUTPUTS = [
    "qapi-introspect.c",
    "qapi-introspect.h",
    "qapi-types.c",
    "qapi-types.h",
    "qapi-visit.h",
    "qapi-visit.c",
    "qapi-commands.h",
    "qapi-commands.c",
    "qapi-init-commands.h",
    "qapi-init-commands.c",
    "qapi-events.h",
    "qapi-events.c",
    "qapi-emit-events.c",
    "qapi-emit-events.h",
]

def qapi_module_outputs(module, with_commands = _WITH_COMMANDS):
    outs = [
        "qapi-types-{}.c",
        "qapi-types-{}.h",
        "qapi-visit-{}.c",
        "qapi-visit-{}.h",
    ]
    if with_commands:
        outs += [
            "qapi-events-{}.c",
            "qapi-events-{}.h",
            "qapi-commands-{}.c",
            "qapi-commands-{}.h",
            "qapi-commands-{}.trace-events",
        ]
    return [o.format(module) for o in outs]

QAPI_OUTPUTS = QAPI_NONMODULE_OUTPUTS + [
    "qapi-builtin-types.c",
    "qapi-builtin-visit.c",
    "qapi-builtin-types.h",
    "qapi-builtin-visit.h",
] + [o for m in QAPI_ALL_MODULES for o in qapi_module_outputs(m)]

# meson.build: qapi_trace_events
QAPI_TRACE_EVENTS = [o for o in QAPI_OUTPUTS if o.endswith(".trace-events")]
