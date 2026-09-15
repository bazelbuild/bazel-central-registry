#!/usr/bin/env python3
"""Pin the wheels of one of Isaac Sim's pip prebundles.

Some extensions expect a `pip_prebundle` directory of vendored wheels on
`sys.path`. Upstream builds it with pip, from the package list in a
`deps/pip_*.toml`; this reads the same list and records where each wheel is and
what it hashes to, so the build can fetch them without resolving anything.

Only prebundles whose packages all come from PyPI can be locked this way. The
lula and cumotion bundles cannot: their wheels are NVIDIA-authored and ship
inside a closed packman package, which is why their `.toml` passes
`--no-index -f <packman package>`.

The package lists are exact -- `install_dependencies = false`, with transitive
dependencies spelled out -- so nothing here resolves a dependency graph; it only
looks up the wheels each version publishes.

A prebundle is one directory per host, not one directory for all hosts, so a
package that publishes per-platform wheels is fine: the lock records one entry
per platform and the module extension fetches the ones matching the host, the
same way the Kit kernel package is chosen. What a lock cannot express is a
package with no wheel for a platform this module supports, which is an error
rather than a silent gap.

Usage:
    bazel run @isaacsim//bazel:gen_pip_lock -- \\
        --toml deps/pip_urdf_usd.toml --out bazel/pip_urdf_usd_lock.json
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import sys
import urllib.request

# The packages = [...] block, and "name==version" inside it. tomllib would do,
# but a dependency-free reader keeps this runnable anywhere.
#
# The closing bracket has to be the one at the start of a line: a requirement
# may carry an extra, and "newton[sim]==1.2.0" would otherwise end the block.
_PACKAGES_BLOCK = re.compile(r"^packages\s*=\s*\[(.*?)^\]", re.S | re.M)
_REQUIREMENT = re.compile(r'"\s*([A-Za-z0-9_.\-]+(?:\[[^\]]*\])?)\s*(==)?\s*([^"\s]*)\s*"')
_TARGET = re.compile(r'^target\s*=\s*"[^"]*/([^"/]+)"', re.M)
_NO_INDEX = "--no-index"

# The platforms a prebundle is locked for, as packman spells them and as a
# wheel's platform tag does.
#
# x86_64 only, though the .toml files claim aarch64 too. PyOpenGL-accelerate,
# which pip_newton.toml requires, publishes no aarch64 wheel at all -- on that
# platform upstream's pip builds it from its sdist, which a lock cannot express
# and this build will not do. Leaving aarch64 out says so; adding it back means
# finding an answer for that package first.
_PLATFORMS = {"manylinux_2_35_x86_64": "x86_64"}

# Kit embeds CPython 3.12, so that is the only interpreter a prebundle is ever
# imported by.
_ABI = "312"


def workspace_relative(path: str) -> str:
    """Resolve a relative path against the directory `bazel run` was invoked in."""
    expanded = os.path.expanduser(path)
    root = os.environ.get("BUILD_WORKING_DIRECTORY")
    if os.path.isabs(expanded) or not root:
        return expanded
    return os.path.join(root, expanded)


def requirements(toml: str) -> list[tuple[str, str | None]]:
    """The (name, version) pairs a prebundle asks for.

    A version of None means the .toml did not pin one. Upstream then takes
    whatever pip resolves at build time; this resolves it once, here, and writes
    the answer into the lock, which is the reproducible version of the same
    thing. Nothing is left to resolve later, because the lock is what the build
    reads.
    """
    block = _PACKAGES_BLOCK.search(toml)
    if not block:
        raise SystemExit("no packages = [...] block found")

    wanted = []
    for name, operator, version in _REQUIREMENT.findall(block.group(1)):
        if operator == "==" and version:
            wanted.append((name.split("[")[0], version))
        elif not operator and not version:
            wanted.append((name.split("[")[0], None))
        else:
            raise SystemExit(
                f"{name} is constrained rather than pinned or left open; this prebundle needs a resolver",
            )
    return wanted


def _entry(name: str, version: str, wheel: dict, platform: str | None) -> dict:
    entry = {
        "name": name,
        "version": version,
        "url": wheel["url"],
        "sha256": wheel["digests"]["sha256"],
        "size": wheel["size"],
    }
    if platform:
        entry["platform"] = platform
    return entry


def _python_ok(filename: str) -> bool:
    """Whether a wheel is importable by the CPython 3.12 Kit embeds.

    Read from the tags rather than by substring: filenames run from the tidy
    (`coacd-1.0.7-cp39-abi3-manylinux...`) to glfw's
    `py2.py27.py3.[...].p312.p313-none-manylinux2014_x86_64`, and both are
    perfectly ordinary wheels.
    """
    fields = filename[: -len(".whl")].split("-")
    if len(fields) < 3:
        return False
    python_tags, abi_tag = fields[-3].split("."), fields[-2]

    if abi_tag == "cp" + _ABI:
        return True
    # A stable-ABI wheel works on any interpreter at or above the one it was
    # built for, and every cp3x tag here is below 3.12.
    if abi_tag == "abi3":
        return True
    # No extension modules of its own, or ones loaded through ctypes: usable if
    # any tag names Python 3.
    return abi_tag == "none" and any(tag.startswith(("py3", "cp3", "p3")) for tag in python_tags)


def wheels_for(name: str, version: str | None) -> tuple[str, list[dict]]:
    """The wheels to record for a package, and the version they came from.

    One universal wheel if the package publishes one, otherwise one per
    platform this module supports.
    """
    suffix = f"/{version}" if version else ""
    url = f"https://pypi.org/pypi/{name}{suffix}/json"
    with urllib.request.urlopen(url) as response:
        metadata = json.load(response)

    resolved = version or metadata["info"]["version"]
    files = metadata["urls"] if version else metadata["releases"][resolved]
    wheels = [f for f in files if f["packagetype"] == "bdist_wheel"]
    if not wheels:
        raise SystemExit(f"{name}=={resolved} publishes no wheel")

    universal = [f for f in wheels if f["filename"].endswith("-none-any.whl")]
    if universal:
        if len(universal) != 1:
            raise SystemExit(
                f"{name}=={resolved} publishes {len(universal)} universal wheels",
            )
        return resolved, [_entry(name, resolved, universal[0], None)]

    # Per-platform. Take the most specific interpreter tag available, so a
    # package shipping both cp312 and abi3 wheels contributes one entry.
    entries = []
    for platform, arch in _PLATFORMS.items():
        candidates = [
            f for f in wheels if "manylinux" in f["filename"] and arch in f["filename"] and _python_ok(f["filename"])
        ]
        if not candidates:
            raise SystemExit(
                f"{name}=={resolved} publishes no CPython 3.12 wheel for "
                f"{platform}; a prebundle cannot leave a platform short",
            )

        # Prefer the wheel built for this exact interpreter over a stable-ABI or
        # pure-Python one, the way pip orders them.
        def rank(f):
            abi = f["filename"][: -len(".whl")].split("-")[-2]
            return {"cp" + _ABI: 0, "abi3": 1}.get(abi, 2)

        entries.append(_entry(name, resolved, sorted(candidates, key=rank)[0], platform))
    return resolved, entries


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--toml", required=True, help="deps/pip_<name>.toml to read")
    ap.add_argument("--out", required=True, help="lock file to write")
    args = ap.parse_args()

    toml = pathlib.Path(workspace_relative(args.toml)).read_text(encoding="utf-8")
    if _NO_INDEX in toml:
        raise SystemExit(
            f"{args.toml} installs from a local package directory ({_NO_INDEX}), so its wheels are not on PyPI",
        )

    target = _TARGET.search(toml)
    lock = {
        "//": {
            "prebundle": target.group(1) if target else "",
            "generated-from": os.path.basename(args.toml),
        },
    }
    for name, version in requirements(toml):
        resolved, entries = wheels_for(name, version)
        for entry in entries:
            lock[os.path.basename(entry["url"])] = entry
        note = "" if version else "  (unpinned upstream, resolved here)"
        platforms = [e["platform"] for e in entries if "platform" in e]
        where = " [%s]" % ", ".join(platforms) if platforms else ""
        print(f"  {name}=={resolved}{where}{note}", file=sys.stderr)

    out = workspace_relative(args.out)
    pathlib.Path(out).write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
    print(f"wrote {out}: {len(lock) - 1} wheels", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
