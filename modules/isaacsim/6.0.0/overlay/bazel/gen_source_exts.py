#!/usr/bin/env python3
"""Classify Isaac Sim's source extensions and emit the source-buildable list.

Isaac Sim is Apache-2.0, so its `isaacsim.*` extensions are built from source
rather than pulled as prebuilts. Not all of them can be, though, so this walks the
release tarball and sorts them:

  pure  -- Python only; `isaacsim_extension` handles these today
  ogn   -- carries .ogn node definitions, needing the OGN generator that ships
           inside the closed omni.graph.tools
  c++   -- carries C++/CUDA sources, needing a native build against the carb SDK,
           USD and PhysX headers
  pip-bundle -- expects a `pip_prebundle` directory of vendored wheels that only
           the published package carries

Extensions live in both `source/extensions/` and `source/deprecated/`; the latter
are still shipped and still depended on by the stock app configs.

Usage:
    bazel run @isaacsim//bazel:gen_source_exts -- \
        --tarball <IsaacSim-x.y.z.tar.gz> [--out bazel/source_exts.bzl] [--report]
"""

from __future__ import annotations

import argparse
import collections
import os
import pathlib
import re
import sys
import tarfile

# An extension that puts `pip_prebundle` on sys.path expects a directory of
# vendored wheels that only exists in the published package -- the source tree has
# no payload. Built from source it raises FileNotFoundError at startup, which in
# Isaac Sim's case breaks omni.kit.async_engine and cascades into "No module
# named ..." for everything downstream. Detected rather than listed by name, so
# new ones are caught automatically.
_PIP_BUNDLE_MARKER = b"pip_prebundle"

# A prebundle whose wheels are all on PyPI can be built here; see
# //bazel:gen_pip_lock.py. lula and cumotion are not: their wheels are
# NVIDIA-authored and ship inside a closed packman package.
_BUILDABLE_PREBUNDLES = {"isaac_newton_prebundle", "isaac_urdf_usd_prebundle"}

# premake links the prebundle in from a packman target-dep:
#     { "$root/_build/target-deps/isaac_urdf_usd_prebundle",
#       ext.target_dir .. "/pip_prebundle" }
_PREBUNDLE_ENTRY = re.compile(
    r'"\$root/_build/target-deps/([^"/]+)"\s*,\s*ext\.target_dir\s*\.\.\s*"/pip_prebundle"',
)

# An extension can declare a Python module whose files do not exist in the source
# tree at all, because a generator produces them at build time -- the USD schema
# extensions (omni.usd.schema.newton) are only config/, data/ and docs/, with
# `usd.schema.newton` emitted by usdGenSchema. Built from source they load but
# raise "No module named ..." on first import.
_PY_MODULE = re.compile(r'\[\[python\.module\]\]\s*\nname\s*=\s*"([^"]+)"')


def declared_modules_present(toml: str, files: set[str]) -> bool:
    """Whether every [[python.module]] the manifest declares exists in source."""
    for module in _PY_MODULE.findall(toml):
        as_path = module.replace(".", "/")
        if any(
            f == f"{as_path}/__init__.py" or f.startswith(f"{as_path}/")
            for f in files
        ):
            continue
        if any(f.startswith("python/") for f in files):
            continue
        return False
    return True

_ENTRY = re.compile(r"^[^/]+/source/(extensions|deprecated)/([^/]+)/(.*)$")

# premake5.lua states where each extension's files go, as pairs of
#   { "<source path>", ext.target_dir .. "/<destination>" }
# inside repo_build.prebuild_copy / prebuild_link blocks. Both the nested form and
# the flat single-pair form occur. Destinations built from other variables (the
# `ogn.*` paths) belong to extensions excluded for needing OGN codegen anyway.
_PREBUILD_PAIR = re.compile(
    r'"([^"]+)"\s*,\s*ext\.target_dir(?:\s*\.\.\s*"([^"]*)")?',
)


# Some extensions assemble themselves from a packman target-dep rather than from
# their own tree, e.g. omni.usd.schema.newton copies
#   $root/_build/target-deps/isaac_newton_prebundle/newton_usd_schemas
# into its package. That payload does not exist in the source release at all, so
# the extension cannot be built from source: it starts and then fails on
# "No module named ...".
_EXTERNAL_SOURCE = ("$root", "_build/target-deps")

# ...but some of those payloads are packages this build can fetch itself, the
# same way it fetches the interface headers of omni_physics. Keyed by the
# directory packman links the package as, which is what premake names.
_BUILDABLE_PAYLOADS = {"generic_model_output", "sensor-checker"}

# The package a target-dep path belongs to is the segment after target-deps/,
# not the last one: the copies name a directory inside the package, e.g.
#   %{root}/_build/target-deps/generic_model_output/%{platform}/%{config}/omni/sensors
_TARGET_DEP_PACKAGE = re.compile(r"_build/target-deps/([^/\"]+)")


def workspace_relative(path: str) -> str:
    """Resolve a relative path against the directory `bazel run` was invoked in.

    Under `bazel run` the working directory is the runfiles tree, so a relative
    --out would write the regenerated file into the build output instead of the
    source tree the caller meant.
    """
    p = pathlib.Path(path).expanduser()
    root = os.environ.get("BUILD_WORKING_DIRECTORY")
    if p.is_absolute() or not root:
        return str(p)
    return str(pathlib.Path(root) / p)


def premake_mapping(premake: str) -> tuple[dict[str, str], dict[str, str]]:
    """(source-relative path -> destination, packman package -> destination).

    A source outside the tree is a packman target-dep. Most are payloads that
    only the published package carries, but some -- a pip prebundle, the RTX
    sensor packages -- are ones this build can fetch itself, so they are
    returned rather than reduced to a flag.
    """
    mapping = {}
    external = {}
    for src, dest in _PREBUILD_PAIR.findall(premake):
        if any(marker in src for marker in _EXTERNAL_SOURCE):
            package = _TARGET_DEP_PACKAGE.search(src)
            external[package.group(1) if package else src] = dest.lstrip("/")
            continue
        mapping[src] = dest.lstrip("/")
    return mapping, external

# Each extension's premake5.lua is the authoritative source->destination mapping,
# and it differs per extension: isaacsim.core.experimental.utils, for instance,
# copies python/mock/*.py *flat* into the package root, which is where
# `isaacsim.core.experimental.utils.ops` actually comes from. Guessing the layout
# instead silently produces an extension whose submodules cannot be imported.
# Entries are scanned across the whole file rather than per prebuild block,
# because both a multi-line block and a one-liner
# (`repo_build.prebuild_link { "docs", ext.target_dir .. "/docs" }`) are used, and
# the brace nesting differs between them.
# premake's ogn helpers place generated code by module path and copy the node
# directories in beside it:
#     local ogn = get_ogn_project_information(ext, "isaacsim/replicator/writers")
#     add_ogn_dependencies(ogn, { "python/nodes" })
# Neither shows up in the prebuild rules, so they are read separately.
_OGN_PROJECT = re.compile(r'get_ogn_project_information\s*\(\s*ext\s*,\s*"([^"]+)"')
_OGN_NODE_DIRS = re.compile(r"add_ogn_dependencies\s*\(\s*ogn\s*,\s*\{([^}]*)\}")


def ogn_information(lua: str) -> dict | None:
    """The module path and node directories for an extension with .ogn nodes."""
    module = _OGN_PROJECT.search(lua)
    if not module:
        return None
    # add_ogn_dependencies can be called more than once, and is: an extension
    # with both Python and C++ nodes registers "python/nodes" and "nodes".
    node_dirs = []
    for group in _OGN_NODE_DIRS.findall(lua):
        for directory in re.findall(r'"([^"]+)"', group):
            if directory not in node_dirs:
                node_dirs.append(directory)
    return {"module": module.group(1), "node_dirs": node_dirs}


# A prebuild entry pairs a source path with where it lands:
#     { "docs", ext.target_dir .. "/docs" }
#     { "python/impl", ogn.python_target_path .. "/impl" }
# Both forms occur, sometimes in one-line blocks and sometimes nested, so the
# entries are matched loosely and the destination expression is interpreted
# below. Destinations built from anything else -- an OGN include path, say --
# are not understood and are dropped, which is visible as a missing mapping
# rather than a wrong one.
_PREBUILD_ENTRY = re.compile(r'\{\s*"([^"]+)"\s*,\s*([^{}]*?)\s*,?\s*\}')

# ogn_helpers.lua: python_root_path is the extension root, python_target_path is
# the extension's Python package inside it, and tests hang off that.
_OGN_PATHS = {
    "ext.target_dir": "",
    "ogn.python_root_path": "",
    "ogn.python_target_path": "{module}",
    "ogn.python_tests_target_path": "{module}/tests",
}

# Several premake5.lua files spell the package path once and reuse it:
#     local python_target_path = "isaacsim/sensors/experimental/physics"
#     { "python/impl", ext.target_dir .. "/" .. python_target_path .. "/impl" }
# Only plain string literals are substituted; anything computed is left alone
# and drops the entry, which shows up as a missing mapping rather than a wrong
# one.
_LOCAL_STRING = re.compile(r'^\s*local\s+([A-Za-z_]\w*)\s*=\s*"([^"]*)"\s*$', re.M)


def destination(
    expression: str,
    module: str | None,
    locals_: dict[str, str] | None = None,
) -> str | None:
    """Where a premake destination expression puts files, relative to the root."""
    parts = [part.strip() for part in expression.split("..")]
    out = []
    for part in parts:
        if part.startswith('"') and part.endswith('"'):
            out.append(part[1:-1])
        elif part in _OGN_PATHS:
            root = _OGN_PATHS[part]
            if "{module}" in root and not module:
                return None
            out.append(root.format(module=module or ""))
        elif locals_ and part in locals_:
            out.append(locals_[part])
        else:
            return None
    return "".join(out).strip("/")


def prebuild_mapping(lua: str, module: str | None = None) -> dict[str, str]:
    """src path/glob -> destination directory, relative to the extension root."""
    locals_ = dict(_LOCAL_STRING.findall(lua))
    mapping = {}
    for src, expression in _PREBUILD_ENTRY.findall(lua):
        if not any(root in expression for root in _OGN_PATHS):
            continue
        dest = destination(expression, module, locals_)
        if dest is not None:
            mapping[src] = dest
    return mapping


def classify(tarball: str) -> dict[str, dict]:
    exts: dict[str, dict] = collections.defaultdict(
        lambda: {
            "ogn": 0,
            "cpp": 0,
            "dir": None,
            "layout": None,
            "pip_bundle": False,
            "mapping": {},
            "ogn_info": None,
            "prebundle": None,
            "external_payload": False,
            "ogn_dirs": set(),
            "payloads": {},
            "files": set(),
            "toml": "",
            "modules_present": True,
        },
    )
    with tarfile.open(tarball) as tf:
        for member in tf.getmembers():
            m = _ENTRY.match(member.name)
            if not m:
                continue
            subdir, ext, rel = m.groups()
            info = exts[ext]
            info["dir"] = subdir
            if rel.endswith(".ogn"):
                info["ogn"] += 1
            elif rel.endswith((".cpp", ".cc", ".cu")):
                # Only translation units: an extension that publishes headers
                # for others to compile against has nothing of its own to build.
                info["cpp"] += 1
            if rel.startswith("python/"):
                info["layout"] = "python/"
            elif info["layout"] is None and rel.split("/")[0] == "isaacsim":
                info["layout"] = "namespaced"
            if member.isfile() and rel.endswith((".py", ".toml")):
                fh = tf.extractfile(member)
                if fh and _PIP_BUNDLE_MARKER in fh.read():
                    info["pip_bundle"] = True
            if member.isfile() and rel == "premake5.lua":
                fh = tf.extractfile(member)
                if fh:
                    mapping, external = premake_mapping(
                        fh.read().decode("utf-8", "replace"),
                    )
                    info["mapping"] = mapping
                    info["payloads"] = {
                        name: dest
                        for name, dest in external.items()
                        if name in _BUILDABLE_PAYLOADS
                    }
                    # A prebundle this build can produce only settles the
                    # extension that takes the whole of it. Two others copy a
                    # subdirectory of the same packman package somewhere else
                    # entirely (omni.usd.schema.newton takes
                    # isaac_newton_prebundle/newton_usd_schemas into its own
                    # package), and pip_prebundle does not describe that.
                    info["external_payload"] = any(
                        not (name in _BUILDABLE_PREBUNDLES and
                             dest == "pip_prebundle") and
                        name not in _BUILDABLE_PAYLOADS
                        for name, dest in external.items()
                    )
            if member.isfile():
                info["files"].add(rel)
                if rel.endswith(".ogn"):
                    info["ogn_dirs"].add(rel.rsplit("/", 1)[0])
            if rel == "config/extension.toml" and member.isfile():
                fh = tf.extractfile(member)
                if fh:
                    info["toml"] = fh.read().decode("utf-8", "replace")
            if rel == "premake5.lua" and member.isfile():
                fh = tf.extractfile(member)
                if fh:
                    lua = fh.read().decode("utf-8", "replace")
                    info["ogn_info"] = ogn_information(lua)
                    module = info["ogn_info"]["module"] if info["ogn_info"] else None
                    info["mapping"] = prebuild_mapping(lua, module)
                    prebundle = _PREBUNDLE_ENTRY.search(lua)
                    info["prebundle"] = prebundle.group(1) if prebundle else None

    for info in exts.values():
        info["modules_present"] = declared_modules_present(info["toml"], info["files"])

    for ext, info in exts.items():
        if info["pip_bundle"] and info["prebundle"] not in _BUILDABLE_PREBUNDLES:
            info["class"] = "pip-bundle"
        elif info["external_payload"]:
            info["class"] = "external-payload"
        elif not info["modules_present"]:
            info["class"] = "generated"
        elif info["cpp"]:
            info["class"] = "c++"
        elif info["ogn"] and not info["ogn_info"]:
            # .ogn nodes whose premake does not say where the generated code
            # goes -- nothing to guess from.
            info["class"] = "ogn"
        elif not info["mapping"]:
            # Without premake's layout rules the tree would have to be guessed,
            # and a wrong guess yields an extension Kit loads but cannot import.
            info["class"] = "no-mapping"
        else:
            info["class"] = "pure"
    return dict(exts)


_HEADER = '''\
"""The Isaac Sim extensions that can be built from source.

GENERATED from the Isaac Sim source tree by //bazel:gen_source_exts.py; see
//bazel/README.md.

Extensions with C++ are excluded; extensions with .ogn nodes are included, with
the information needed to generate their databases. Excluded, with reasons:
  * extensions with .ogn nodes whose premake does not declare where the
    generated code belongs
  * extensions with C++/CUDA sources -- need a native build against the carb
    SDK and USD headers
  * extensions that put `pip_prebundle` on sys.path and whose wheels are not on
    PyPI -- the ones that are get their prebundle built here
  * extensions declaring a Python module absent from the source tree -- a
    generator (usdGenSchema, pybind) produces it at build time
"""

# extension name -> {"dir": subdirectory of source/, "mapping": premake's
# source-path -> destination-directory rules, both relative to the extension,
# "ogn": where its generated OmniGraph code goes, if it has .ogn nodes,
# "pip_prebundle": the vendored-wheel bundle it needs, if any,
# "payloads": packman package -> where its payload goes inside the extension}
ISAACSIM_SOURCE_EXTS = {
'''

# The extensions with C++ sources. Their layout is described the same way, but
# assembling one also needs a build recipe for its plugin; //bazel:native_exts.bzl
# says which of them have one.
_NATIVE_HEADER = '''
ISAACSIM_NATIVE_EXTS = {
'''


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tarball", required=True)
    ap.add_argument("--out", default="bazel/source_exts.bzl")
    ap.add_argument("--report", action="store_true", help="Print the classification.")
    args = ap.parse_args()

    exts = classify(workspace_relative(args.tarball))
    if args.report:
        tally = collections.Counter(v["class"] for v in exts.values())
        print(f"{len(exts)} extensions: {dict(tally)}", file=sys.stderr)
        for kind in ("ogn", "c++", "pip-bundle", "external-payload", "no-mapping"):
            names = sorted(e for e, v in exts.items() if v["class"] == kind)
            print(f"\n{kind} ({len(names)}):", file=sys.stderr)
            for n in names:
                print(f"  {n}", file=sys.stderr)

    pure = {e: v for e, v in exts.items() if v["class"] == "pure"}
    native = {e: v for e, v in exts.items() if v["class"] == "c++"}
    body = _render(pure) + _NATIVE_HEADER + _render(native)
    out = workspace_relative(args.out)
    pathlib.Path(out).write_text(_HEADER + body)
    print(
        f"wrote {out}: {len(pure)} source-buildable extensions, "
        f"{len(native)} native ones described",
        file=sys.stderr,
    )
    return 0


def _render(exts: dict) -> str:
    chunks = []
    for e in sorted(exts):
        info = exts[e]
        chunks.append('    "%s": {\n' % e)
        chunks.append('        "dir": "%s",\n' % info["dir"])
        chunks.append('        "mapping": {\n')
        for src in sorted(info["mapping"]):
            chunks.append('            "%s": "%s",\n' % (src, info["mapping"][src]))
        chunks.append("        },\n")
        if info["prebundle"] in _BUILDABLE_PREBUNDLES:
            chunks.append('        "pip_prebundle": "%s",\n' % info["prebundle"])
        if info["payloads"]:
            chunks.append('        "payloads": {\n')
            for name in sorted(info["payloads"]):
                chunks.append('            "%s": "%s",\n' % (name, info["payloads"][name]))
            chunks.append("        },\n")
        if info["ogn"] and info["ogn_info"]:
            ogn = info["ogn_info"]
            chunks.append('        "ogn": {\n')
            chunks.append('            "module": "%s",\n' % ogn["module"])
            chunks.append('            "node_dirs": [%s],\n' % ", ".join(
                '"%s"' % d for d in ogn["node_dirs"]
            ))
            # Where the .ogn files actually are. A glob over a directory that
            # does not exist is an error, and which of python/nodes and nodes/
            # an extension uses is not something the premake rules say.
            chunks.append('            "src_dirs": [%s],\n' % ", ".join(
                '"%s"' % d for d in sorted(info["ogn_dirs"])
            ))
            chunks.append("        },\n")
        chunks.append("    },\n")
    return "".join(chunks) + "}\n"


if __name__ == "__main__":
    sys.exit(main())
