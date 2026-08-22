# The Bazel build of Isaac Sim

Everything in this directory is the Bazel overlay for the Isaac Sim source
release; upstream builds with premake and packman instead. It exists so
`bazel run @isaacsim//:isaacsim` starts Isaac Sim with nothing installed on the
host and nothing fetched at run time.

## What comes from where

| Piece | Licensing | How it is obtained |
| --- | --- | --- |
| Omniverse Kit kernel (the runtime) | closed | `kit.kernel()`, the package `deps/kit-sdk.packman.xml` pins |
| `omni.*` Kit extensions (RTX renderer, `omni.graph`, `omni.physx`, …) | closed | `kit.extensions()`, pinned in `exts_lock.json` |
| 119 `isaacsim.*` extensions | Apache-2.0 | **built from source**, `source_exts.bzl` and `native_exts.bzl` -- Python, OmniGraph node code, two PyPI prebundles, two vendored packman payloads, and fifteen with C++ |
| 5 `isaacsim.*` extensions whose payload is not published | Apache-2.0 source, prebuilt binary | `kit.extensions()`, same lock |

The lock and the source-built set never overlap: `kit.bzl` skips downloading any
package this module builds, so there is one decision in one place. What is left
in the lock is the `omni.*` closure plus the five `isaacsim.*` extensions not
built here yet (243 of the 266 archives it records). Building Isaac Sim entirely from source is
not possible and is not what upstream does either — its own build downloads the
same closed `kit-kernel` package this module pins. Every archive is pinned by
sha256, so builds are reproducible and work offline once the repository cache is
warm.

## Files

```
kit.bzl            module extension: kit.kernel() + kit.extensions()
private/kit_repo.bzl   the repository rules behind them
ext_folder.bzl     stages the prebuilt extensions as one --ext-folder
cc.bzl             builds the C++ half: carbonite plugins and pybind modules
native_exts.bzl    which C++ extensions have a recipe, and what it produces
ogn.bzl            runs the OmniGraph node generator over the .ogn sources
pip.bzl            unpacks pinned PyPI wheels into an extension's pip_prebundle
pip_urdf_usd_lock.json  GENERATED wheel pins for that prebundle
private/exec.bzl   executable_file(): an executable copy of a script
exts_lock.json     GENERATED pins for the closed extension closure
source_exts.bzl    GENERATED set built from source, with premake layouts
src_ext.bzl        isaacsim_extension(): builds one Kit extension from source
defs.bzl           public API: isaacsim_kit_binary / isaacsim_kit_test
run_kit.sh         launcher: resolves kernel, .kit and ext folders from runfiles
deps.kit           overlay: dependencies the shipped packages omit
hermetic.kit       overlay: no registry, no telemetry -- merged into every run
registry.kit       overlay: the Isaac Sim registry, for re-pinning only
kernel_only.kit    minimal app used by //:extensions_test
launch_smoke.py    runs inside Kit in //:launch_test
gen_*.py           regenerate the GENERATED files, on rules_python's
                   interpreter -- `bazel run @isaacsim//bazel:gen_source_exts`
```

One source file is patched, in `../patches`: `omni.kit.loop-isaac` includes fmt
as `"fmt/include/fmt/format.h"`, which is where packman's target-deps layout
puts it, one directory below what the `fmt` module exports.

## Hermeticity

Kit is a plugin runtime that downloads what it is missing, so "it started" and
"it started from what Bazel gave it" are different claims. Five things keep them
the same claim:

* **Everything is pinned.** The kernel digest is in `private/kit_repo.bzl`, the
  extension archives in `exts_lock.json` (266 recorded, 243 downloaded -- the
  rest are built here), the prebundle wheels in `pip_urdf_usd_lock.json`, and
  the source tree in the module's `source.json`. Nothing resolves a version at
  build time.
* **The registry is off at run time** (`hermetic.kit`). A gap in the lock then
  fails the run instead of being papered over by a silent download that leaves
  the build reproducible only on a machine that has already done it. `//:precache`
  is the single target allowed to reach a registry, and it is `manual`.
* **Telemetry is off** (`hermetic.kit`). The stock app config turns anonymous
  usage reporting on.
* **No host Python is involved anywhere.** What runs inside Kit is the CPython
  3.12 the kernel package bundles; what regenerates the two GENERATED files is
  the interpreter `rules_python` pins (`bazel run //bazel:gen_source_exts`).
  Neither is the machine's `python3`, which is what decides the contents of
  `source_exts.bzl` if you let it.
* **The kernel tree is read-only.** Kit's embedded CPython compiles its own
  stdlib on first import and writes `__pycache__` back into the repository,
  after which Bazel reports the repository as modified externally and refetches
  it. The interpreter is configured by carbonite, not from the environment, so
  `PYTHONDONTWRITEBYTECODE` does not reach it; removing write permission does,
  and CPython treats an unwritable cache directory as a cache miss.

Under `bazel test` the launcher also points `HOME`, which is where Kit puts its
data, cache and logs, at the test's own scratch directory — so a download that
did happen could not land in the developer's `~/.local/share/ov` and be found
there by the next run, which would then look hermetic. `launch_smoke.py` asserts
from inside Kit that no enabled extension was loaded from under `HOME`. The
price is that the RTX shader and Warp kernel caches start cold every time;
`bazel run` keeps the real `HOME` and so keeps them.

A test run also turns off Kit's hang detector and crash reporter. The hang
detector's response to a stall is to ask, through `zenity`, whether to terminate
and send a report — under `bazel test` there is nobody to ask, and the test
timeout is the right thing to decide it.

## Which extensions are built from source

Of the 149 `isaacsim.*` extensions in the source release, 119 are built here:
104 that `gen_source_exts.py` can assemble from their premake layout alone, and
fifteen with C++ whose recipes are written by hand in `native_exts.bzl`. The
classifier records why each of the rest is not in the first group:

| Not assemblable as-is | Count | Why |
| --- | --- | --- |
| C++/CUDA sources | 28 | need a build recipe; fifteen have one so far |
| `pip_prebundle` on `sys.path` | 10 | their vendored wheels are NVIDIA-authored, not on PyPI |
| payload from a packman target-dep | 4 | e.g. `omni.usd.schema.newton` copies `$root/_build/target-deps/…`, absent from the source release |
| generated sources | 3 | produced by the build, not shipped |

The last two categories fail the same way if built anyway: the extension starts
and *then* fails to import, so they are detected rather than listed by name.

Not built here does not mean unused. `isaacsim.exp.base` resolves 62
`isaacsim.*` extensions, and every C++ one among them is now built from source.
The prebuilts still in that closure are two whose wheels are NVIDIA-authored and
ship inside a closed packman package (`robot_motion.lula`,
`robot_motion.cumotion`) and four that are not in the source release at all
(`exp.base`, `anim.robot.schema`, `replicator.agent.schema`, `util.debug_draw`
-- the last of which this build does use, for the headers and the static archive
`isaacsim.sensors.physx` links). The other thirteen C++ extensions are not in
this app's closure: the ROS 2 bridge nodes, `hsb.*`, `ucx.nodes`,
`mobility_gen`, `asset.gen.conveyor` and friends are only reached by app configs
this module does not launch, so they are absent rather than substituted.

Both prebundles whose wheels are all on PyPI are built here. The newton one
(`deps/pip_newton.toml`, all Apache-2.0/MIT/BSD) is locked for x86_64 only:
`PyOpenGL-accelerate` publishes no aarch64 wheel, so upstream's pip builds it
from its sdist there, which a lock cannot express.

Two extensions copy a *subdirectory* of that same packman package somewhere
other than `pip_prebundle` -- `omni.usd.schema.newton` takes
`isaac_newton_prebundle/newton_usd_schemas` into its own Python package, and
`omni.usd.schema.mujoco` does the same with the converter's plugins. That is a
different shape from a prebundle and they are still taken prebuilt.

## Vendored wheels

`isaacsim.asset.importer.urdf` expects a `pip_prebundle` directory -- an
unpacked site-packages its `config/extension.toml` adds to `sys.path`. Only the
pin list is in the source tree (`deps/pip_urdf_usd.toml`); upstream builds the
directory with pip and ships the result. All four packages are on PyPI
(Apache-2.0/BSD/MIT), so `gen_pip_lock.py` records their wheels and `pip.bzl`
unpacks them into the same directory -- which is all `pip_install --target`
amounts to for pure-Python wheels.

```bash
bazel run @isaacsim//bazel:gen_pip_lock -- \
    --toml deps/pip_urdf_usd.toml --out bazel/pip_urdf_usd_lock.json
```

## The C++ half

An extension's native part is a carbonite plugin (`lib<ext>.plugin.so` in the
extension's `bin/`), a pybind module beside the Python package that imports it,
or both. The sources are Apache-2.0 and in this tree; what they compile against
is what used to make them unbuildable here, and all of it turns out to be
reachable:

| Needed | From |
| --- | --- |
| carb, omni, kit, fabric headers | the Kit kernel package's own `dev/` directory |
| GSL headers | `gsl` 4.0.0.bcr.1, the registry module — kept because Kit still includes `<gsl/string_span>` |
| OpenUSD headers | `openusd` 25.11, the registry module — the same release NVIDIA builds |
| PhysX SDK and its USD schema | `physx` 5.9.0, the registry module — the same tag NVIDIA builds |
| `omni/physics/*` interfaces | a packman package of headers, pinned like the kernel |
| pybind11 | `pybind11_bazel` 2.11.1.bzl.3, the registry module — the version the Kit SDK builds against |
| Python headers | `rules_python`'s CPython 3.12. Kit embeds 3.12 and refuses to import a module built against another minor version, and `@pybind11` follows whichever toolchain the *root* module made current, so a root module consuming this one has to make 3.12 the default. //tests/MODULE.bazel does |
| `fmt` | the registry module — `omni.kit.loop-isaac` formats its setting paths with it |
| RapidJSON | the registry module — `isaacsim.sensors.rtx` parses its lidar configuration with it |
| the RTX sensor interfaces and their Python payload | two packman packages (`generic-model-output`, `sensor-checker`), pinned like the kernel. NVIDIA-proprietary with no public source |
| CUDA headers and the static runtime | NVIDIA's redistributable components, pinned here at the 12.8 the kernel was built with |
| everything linked | the shared libraries in the pinned prebuilts, named one at a time |

Nothing is linked against a *second* build of USD: Kit loads its own at run
time, and two of them in one process is a crash, not a duplicate, so `openusd`
supplies headers only. PhysX is the exception, because upstream makes it one:
Isaac Sim links the static PhysX libraries into each plugin and so does
`omni.physx`, which is why the `physx` module builds the SDK rather than
stopping at its headers. See that module for the preprocessor configuration
every copy in the process has to agree on.

`rules_cuda` can fetch those redistributables too, and does it well — but only
for the root module: a dependency's `cuda.redist_json` loses to rules_cuda's own
local-toolkit declaration, and `@cuda` then resolves to whatever
`/usr/local/cuda` is on the machine (13.1 here). The same shape as the Python
toolchain: what version a *library* compiles against is not the root module's
choice to make, so both are pinned by name instead. A consumer who configures
rules_cuda is unaffected; nothing here touches `@cuda`.

Three things that are invisible until the extension is loaded rather than built:

* a pybind module that links its extension's plugin needs
  `RUNPATH=$ORIGIN/…/bin` to find it once installed, which is why
  `isaacsim_cc_python_module` takes a `destination`; and
* a module built against the wrong Python minor version loads, logs, and is
  stepped over; and
* a shared library may be linked with undefined symbols and only fail at
  `dlopen`. NVIDIA links the CUDA runtime statically -- their plugins record
  `libcuda.so.1` and no `libcudart` at all -- and a plugin that merely compiles
  against the headers dies on `undefined symbol: cudaMemcpyAsync` the moment
  Kit loads it.

`//:launch_test` fails on any `[Error]` for exactly these reasons: each of them
produces a Kit that still reaches "app ready".

## OmniGraph nodes

An OmniGraph node is declared in a `.ogn` file, from which a database class is
generated -- the interface the node's Python implementation binds against.
Upstream generates them during its premake build, so an extension assembled
without them loads and then fails on first use. `ogn.bzl` runs that generator,
which ships inside the `omni.graph.tools` package this module already downloads,
as a build action; the databases it emits are byte-identical to the ones in
NVIDIA's published packages. Six extensions come from source because of it,
four of which the stock app actually starts.

Layouts come from each extension's `premake5.lua` rather than being assumed.
They genuinely differ — `isaacsim.core.experimental.utils` copies
`python/mock/*.py` **flat** into its package root (that is where
`isaacsim.core.experimental.utils.ops` comes from) while relocating
`python/impl` into a subpackage. A uniform guess produces an extension Kit loads
but whose submodules cannot be imported, which cascades into `No module
named …` across everything downstream.

```bash
bazel run @isaacsim//bazel:gen_source_exts -- \
    --tarball IsaacSim-6.0.0.tar.gz --out bazel/source_exts.bzl --report
```

## How extensions reach Kit

Kit takes extensions as `--ext-folder <dir>`: one directory holding
`<packageId>/config/extension.toml` per extension. Each closed extension is its
own external repository, so something has to gather them under one root.

Bazel does it, at build time. `@isaacsim_kit_exts//:ext_folder`
(`ext_folder.bzl`) stages every file of every package into the runfiles tree as
`_isaacsim_kit_exts/<packageId>/…` with `root_symlinks`, and the launcher passes
that one directory to Kit. Source-built extensions are already directory
artifacts, so they are simply a second `--ext-folder`.

Entries are named by **registry packageId**, matching how Kit names packages it
unpacks itself. Naming them after their Bazel repository makes Kit fail to
resolve dependency versions locally and fall back to the registry, which still
"works" but is no longer hermetic.

The earlier version of this assembled the directory in the launcher instead,
reading a manifest of extension paths and symlinking them into a `mktemp`
directory per run. It worked, but it put a directory Kit depends on outside
anything Bazel tracks; `root_symlinks` is the same layout, built once and
declared.

## Re-pinning the closed extensions

Needed only when the app's extension set changes. Kit itself does the dependency
resolution; the script turns the result into pinned archives. Isaac Sim's
extensions come from a second registry, which its stock app config does not
declare; `registry.kit` adds it for the precache only.

```bash
# resolve the closure against the live registries
bazel run @isaacsim//:precache

# rewrite the lock; --reuse keeps hashes for URLs that did not change, so only
# newly resolved archives are downloaded
bazel run @isaacsim//bazel:gen_exts_lock -- --out bazel/exts_lock.json --reuse \
    --resolved-dir '~/.local/share/ov/data/Kit/isaacsim.exp.base/*/exts/*'
```

## Notes

`--enable_runfiles` is required: Kit resolves its plugins and libraries relative
to the `kit` binary, so it needs a real runfiles tree, not a manifest-only
layout. It is the default on Linux.

Verified on Ubuntu 26.04 with an RTX 4070 (driver 595.71.05). The Kit kernel
bundles its own CPython 3.12, matching the `cp312` extension builds, so no host
Python or Isaac Sim install is involved.
