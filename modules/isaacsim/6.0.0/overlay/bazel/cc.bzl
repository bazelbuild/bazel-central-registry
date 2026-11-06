"""Build the C++ half of an Isaac Sim extension.

An extension's native part is a carbonite plugin: a shared library named
`lib<extension>.plugin.so`, dropped in the extension's `bin/`, which Kit loads
and asks for its interfaces. The sources are Apache-2.0 and in this repository;
what they compile against is what used to make them unbuildable here, and it
turns out to be available:

  * carbonite, `omni.*` and fabric headers ship inside the Kit kernel package
    (`kit/dev/include`, `kit/dev/fabric/include`) -- see
    @isaacsim_kit_kernel//:sdk_headers;
  * OpenUSD headers come from the `openusd` module, the same 25.11 NVIDIA
    builds -- and only the headers, because the libraries Kit loads at run time
    are the prebuilt ones and a second copy of USD in the process would be a
    disaster;
  * `isaacsim.core.includes` is header-only and in this tree.

Linking follows the same rule: against the shared libraries the pinned
prebuilts already carry, never against a second build of them. That is what the
prebuilt dependencies are -- precompiled `.so` files, which a linker resolves
dynamically whatever `linkstatic` says -- so `linkstatic` here decides only what
happens to libraries Bazel builds from source. Those must be absorbed: a plugin
that keeps a `DT_NEEDED` on a library sitting in bazel-out is a plugin Kit
cannot load, since it loads plugins by path with no search path pointing there.
"""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("//bazel:ogn.bzl", "isaacsim_ogn_cpp")

# Isaac Sim's premake writes this from `git describe`; a source release has no
# git, so it is written from the VERSION file and fixed strings. Deterministic
# beats faithful here -- the alternative is a header that changes per checkout.
_VERSION_HEADER = """\
#pragma once
#define ISAACSIM_BUILD_SHA "{sha}"
#define ISAACSIM_BUILD_DATE "{date}"
#define ISAACSIM_BUILD_BRANCH "{branch}"
#define ISAACSIM_BUILD_VERSION "{version}"
#define ISAACSIM_BUILD_REPO "{repo}"
"""

def isaacsim_version_header(name, version):
    """The generated isaacSim/Version.h the plugins include.

    Args:
        name: Target name; the header is exposed as a cc_library of this name.
        version: Version string to report, from the VERSION file.
    """
    native.genrule(
        name = name + "_gen",
        outs = ["_version/isaacSim/Version.h"],
        cmd = "cat > $@ <<'EOF'\n%s\nEOF" % _VERSION_HEADER.format(
            branch = "",
            date = "",
            repo = "https://github.com/isaac-sim/IsaacSim",
            sha = "",
            version = version,
        ),
    )
    cc_library(
        name = name,
        hdrs = [":_version/isaacSim/Version.h"],
        includes = ["_version"],
    )

def isaacsim_interface_headers(name, extension_name, subdir = "extensions", deps = []):
    """The headers one extension publishes for the others to compile against.

    Isaac Sim's extensions talk to each other through carbonite interfaces
    declared in `include/`, so building one native extension usually needs a
    header directory belonging to another. They are all in this repository and
    all Apache-2.0.

    Args:
        name: Target name.
        extension_name: Extension that owns the headers.
        subdir: Whether it lives in source/extensions or source/deprecated.
        deps: Other interface libraries these headers include.
    """
    root = "source/{subdir}/{ext}/include".format(ext = extension_name, subdir = subdir)
    cc_library(
        name = name,
        hdrs = native.glob([root + "/**"]),
        includes = [root],
        deps = deps,
    )

def isaacsim_ogn_cpp_headers(
        name,
        extension_name,
        module,
        ogn_files,
        node_srcs = [],
        config = None,
        python = None,
        python_runtime = None,
        toolchain = None):
    """The generated OmniGraph database headers, as something to compile against.

    A C++ OmniGraph node is hand-written in `nodes/OgnX.cpp` and includes
    `<OgnXDatabase.h>`, which the generator writes. The headers are declared
    individually so their directory can go on the include path.

    Args:
        name: Target name; a cc_library that puts the headers on the path.
        extension_name: Extension that owns the nodes.
        module: Its Python module path, e.g. "isaacsim/robot/wheeled_robots/nodes".
        ogn_files: The node definitions.
        node_srcs: The rest of the node directories -- icons and category
            configuration a .ogn refers to by relative path.
        config: The generator's configuration directory.
        python: Interpreter to run the generator with.
        python_runtime: That interpreter's tree.
        toolchain: kit_ogn_toolchain tree.
    """
    isaacsim_ogn_cpp(
        name = name + ".gen",
        config = config,
        extension_name = extension_name,
        include_dir = name + ".include",
        module = module,
        node_srcs = node_srcs,
        ogn_files = ogn_files,
        python = python,
        python_runtime = python_runtime,
        toolchain = toolchain,
    )

    cc_library(
        name = name,
        hdrs = [":" + name + ".gen"],
        includes = [name + ".include"],
    )

def isaacsim_cc_plugin(
        name,
        extension_name,
        srcs,
        copts = [],
        deps = [],
        includes = [],
        **kwargs):
    """A carbonite plugin shared library for one extension.

    Args:
        name: Target name. The library itself is always named after the
            extension, because that is how Kit finds it.
        extension_name: Extension id, e.g. "isaacsim.core.api".
        srcs: Its C++ sources and private headers.
        copts: Additional compiler options -- premake turns specific warnings
            off per extension.
        deps: Additional cc_library dependencies.
        includes: Additional include directories, relative to the package.
        **kwargs: Passed through to cc_binary.
    """
    cc_binary(
        name = "lib{ext}.plugin.so".format(ext = extension_name),
        srcs = srcs,
        copts = [
            "-fvisibility=hidden",
            "-std=c++17",
        ] + copts,
        includes = includes,
        linkopts = ["-Wl,--as-needed"],
        linkshared = True,
        linkstatic = True,
        deps = deps + [
            Label("@isaacsim_kit_kernel//:carb"),
        ],
        **kwargs
    )

    native.alias(
        name = name,
        actual = "lib{ext}.plugin.so".format(ext = extension_name),
    )

    # An extension's own pybind module usually links against its plugin, the
    # way premake's `links { "<ext>.plugin" }` does. A cc_binary cannot be
    # depended on, so the shared library is offered as one.
    cc_library(
        name = name + ".lib",
        srcs = ["lib{ext}.plugin.so".format(ext = extension_name)],
    )

def isaacsim_cc_python_module(
        name,
        module_name,
        srcs,
        destination = None,
        deps = [],
        includes = [],
        **kwargs):
    """A pybind11 module for one extension, named the way CPython imports it.

    Args:
        name: Target name.
        module_name: Module as Python imports it, e.g. "_isaac_utils". The file
            carries the ABI tag of Kit's own CPython 3.12, which is what
            imports it -- and which rejects a module built against another
            minor version outright.
        srcs: Its C++ sources and private headers.
        destination: Where the module ends up inside the extension, e.g.
            "isaacsim/core/experimental/prims/bindings". Required when the
            module links against the extension's own plugin: the plugin lives
            in the extension's bin/, and the loader has to be told how to walk
            there from wherever the module was installed.
        deps: Additional cc_library dependencies.
        includes: Additional include directories, relative to the package.
        **kwargs: Passed through to cc_binary.
    """
    rpaths = []
    if destination:
        up = "/".join([".."] * len(destination.split("/")))
        rpaths = [
            "-Wl,-rpath,$$ORIGIN/{up}/bin".format(up = up),
            "-Wl,-rpath,$$ORIGIN",
        ]

    cc_binary(
        name = "{module}.cpython-312-x86_64-linux-gnu.so".format(module = module_name),
        srcs = srcs,
        copts = [
            "-fvisibility=hidden",
            "-std=c++17",
        ],
        includes = includes,
        linkopts = ["-Wl,--as-needed"] + rpaths,
        linkshared = True,
        linkstatic = True,
        deps = deps + [
            Label("@isaacsim_kit_kernel//:carb"),
            Label("@pybind11//:pybind11"),
        ],
        **kwargs
    )

    native.alias(
        name = name,
        actual = "{module}.cpython-312-x86_64-linux-gnu.so".format(module = module_name),
    )
