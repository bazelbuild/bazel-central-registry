"""Measure and admit a static Linux x86_64 ELF without host ELF utilities."""

import hashlib
import json
from pathlib import Path
import struct
import sys


# Source and lock fields in the schema-1 QEMU build manifest.
# Optional pins are null for builds that did not supply the corresponding lock.
_SOURCE_KEYS = (
    "qemu_version",
    "source_sha256",
    "patch_series_sha256",
    "patches",
    "build_inputs_lock_sha256",
    "runtime_tools_lock_sha256",
)


def verifier_inputs(provenance, config):
    pins = {key: provenance[key] for key in _SOURCE_KEYS}
    args = config["configure_args"]
    if not isinstance(args, list) or not all(isinstance(arg, str) for arg in args):
        raise ValueError("configure_args must be a list of strings")
    if config["config_host"]["CONFIG_MODULES"] is not False:
        raise ValueError("QEMU build must disable loadable modules")
    return {**pins, "configure_args": args, "modules": False}


def static_elf(data):
    if data[:6] != b"\x7fELF\x02\x01" or len(data) < 64:
        raise ValueError("expected a little-endian ELF64 executable")
    kind, machine = struct.unpack_from("<HH", data, 16)
    if machine != 62 or kind not in (2, 3):  # EM_X86_64; ET_EXEC/ET_DYN
        raise ValueError("expected an x86-64 executable")
    phoff, = struct.unpack_from("<Q", data, 32)
    entsize, count = struct.unpack_from("<HH", data, 54)
    if not count or entsize < 56:
        raise ValueError("expected ELF program headers")
    for i in range(count):
        p_type, _, offset, _, _, size, _, _ = struct.unpack_from(
            "<IIQQQQQQ", data, phoff + i * entsize,
        )
        if p_type == 3:  # PT_INTERP
            raise ValueError("QEMU ELF has PT_INTERP (requires a runtime loader)")
        if p_type != 2:  # PT_DYNAMIC; a static PIE may have one
            continue
        if size % 16 or offset + size > len(data):
            raise ValueError("invalid PT_DYNAMIC")
        for entry in range(offset, offset + size, 16):
            tag, _ = struct.unpack_from("<qQ", data, entry)
            if tag == 0:  # DT_NULL
                break
            if tag == 1:  # DT_NEEDED
                raise ValueError("QEMU ELF has a DT_NEEDED shared library")


def main(argv):
    elf, config_file, out = map(Path, argv[:3])
    provenance, toolchain = map(json.loads, argv[3:])
    data = elf.read_bytes()
    static_elf(data)
    configuration = config_file.read_bytes()
    config = json.loads(configuration)
    receipt = {
        "schema": 1,
        **verifier_inputs(provenance, config),
        "configuration": config,
        "configure_environment": {"LC_ALL": "C", "PATH": "/nonexistent"},
        "configuration_sha256": hashlib.sha256(configuration).hexdigest(),
        "toolchain": toolchain,
        "compiler": toolchain["compiler"],
        "elf_sha256": hashlib.sha256(data).hexdigest(),
        "elf_size": len(data),
        "dt_needed": [],
        "runtime": {"linkage": "static", "interpreter": None, "libc": toolchain["libc"]},
    }
    out.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main(sys.argv[1:])
