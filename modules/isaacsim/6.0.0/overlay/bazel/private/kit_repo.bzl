"""Repository rules for the closed pieces Isaac Sim runs on.

Isaac Sim itself is Apache-2.0, but it does not run alone: it is an application
*on top of* NVIDIA Omniverse Kit, and Kit's kernel plus a large set of `omni.*`
extensions ship only as prebuilt binaries. Isaac Sim's own build does the same
thing -- `deps/kit-sdk.packman.xml` downloads exactly the kernel package pinned
here -- so fetching them is not a shortcut around a source build, it is what
building Isaac Sim means.

Everything is pinned by sha256 and nothing is fetched at run time.

These rules mirror `rules_omniverse`'s `kit.download()` / `kit.extensions()`;
they live here so the module depends only on what the registry already carries.
"""

# NVIDIA publishes the closed Kit binaries on the packman CDN, addressed as
# "<name>@<version>.zip". This is the remote declared by Kit's own
# tools/packman/config.packman.xml.
PACKMAN_CDN = "https://d4i3qtqj3r0z5.cloudfront.net"

# Digests of the kit-kernel archives Isaac Sim 6.0.0 pins in
# deps/kit-sdk.packman.xml, keyed "<version>/<abi>/<config>".
KNOWN_KIT_KERNEL_SHA256 = {
    "110.1.1+production/manylinux_2_35_x86_64/release": "59c139b0229c189661fa653b60a9f604b27465c23f872be1bdc2b57ea589e78b",
    "110.1.1+production/manylinux_2_35_aarch64/release": "ec7c16673f8aca23a9628c3b85f532c264d8541de24ff856e0617b0d9adf1d09",
}

def packman_url(name, version, extension = "zip"):
    """URL of a packman package archive.

    Args:
        name: Package name, e.g. "kit-kernel".
        version: Full package version including platform/config suffixes.
        extension: Archive format the package is published in. packman picks
            per package: the kernel is a zip, the SDK header packages are 7z.

    Returns:
        The download URL. '@' stays literal; '+' must be percent-encoded.
    """
    return "{cdn}/{name}@{version}.{extension}".format(
        cdn = PACKMAN_CDN,
        extension = extension,
        name = name,
        version = version.replace("+", "%2B"),
    )

def target_abi(repository_ctx):
    """packman platform_target_abi for the host, as Kit spells it.

    Args:
        repository_ctx: The repository context, for host os/arch.

    Returns:
        The abi string, e.g. "manylinux_2_35_x86_64".
    """
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch.lower()

    if os_name.startswith("linux"):
        if arch in ("amd64", "x86_64", "x64"):
            return "manylinux_2_35_x86_64"
        if arch in ("aarch64", "arm64"):
            return "manylinux_2_35_aarch64"

    # Isaac Sim 6.0.0 supports Linux and Windows; the kernel is published for
    # both, but only the Linux packages are pinned above.
    fail(
        "no Kit kernel pinned for os={os} arch={arch}; ".format(os = os_name, arch = arch) +
        "pass abi = \"...\" and sha256 = {...} to select one explicitly",
    )

_KERNEL_BUILD = """\
load("{cc_library_bzl}", "cc_library")

exports_files(
    [
        "kit/{kit_executable}",
        "kit/python/bin/python3",
        # premake adds this to every OmniGraph plugin on Linux.
        "kit/dev/ogn/__LinuxStaticLibWorkaround.cpp",
    ],
    visibility = ["//visibility:public"],
)

# Kit resolves its plugins and shared libraries relative to the executable, so
# anything that runs Kit must carry the whole tree in its runfiles.
filegroup(
    name = "dist",
    visibility = ["//visibility:public"],
    srcs = glob(["kit/**"], allow_empty = True),
)

# The CPython the kernel bundles -- the interpreter Kit itself runs, and so the
# one the OmniGraph node generator should run under. Separate from :dist so a
# codegen action does not stage the whole runtime.
filegroup(
    name = "python",
    visibility = ["//visibility:public"],
    srcs = glob(["kit/python/**"], allow_empty = True),
)

# Type and category definitions the node generator reads.
filegroup(
    name = "ogn_config",
    visibility = ["//visibility:public"],
    srcs = glob(["kit/dev/ogn/config/**"], allow_empty = True),
)

# The SDK half of the kernel package: carbonite, omni.* and fabric headers, and
# the carbonite library itself. This is what makes the Apache-2.0 C++ in the
# Isaac Sim tree compilable -- NVIDIA ships the headers an extension author
# needs inside the same package the runtime comes in. The GSL they include
# against comes from the registry module the overlay pins, not from the copy
# bundled inside the kernel archive.
cc_library(
    name = "sdk_headers",
    visibility = ["//visibility:public"],
    hdrs = glob(
        [
            "kit/dev/include/**",
            "kit/dev/fabric/include/**",
        ],
        allow_empty = True,
    ),
    includes = [
        "kit/dev/fabric/include",
        "kit/dev/include",
    ],
    deps = ["{gsl_label}"],
)

# Linked against, not shipped: Kit loads its own copy, and a plugin only needs
# the symbols resolved.
cc_library(
    name = "carb",
    visibility = ["//visibility:public"],
    srcs = ["kit/libcarb.so"],
    deps = [":sdk_headers"],
)
"""

def _kit_kernel_repository_impl(ctx):
    abi = ctx.attr.abi or target_abi(ctx)
    version = "{version}.{abi}.{config}".format(
        version = ctx.attr.version,
        abi = abi,
        config = ctx.attr.config,
    )

    sha256 = ctx.attr.sha256.get(abi, "")
    if not sha256:
        sha256 = KNOWN_KIT_KERNEL_SHA256.get(
            "{v}/{abi}/{cfg}".format(v = ctx.attr.version, abi = abi, cfg = ctx.attr.config),
            "",
        )
    if not sha256:
        fail(
            "no sha256 known for kit-kernel {v} on {abi} ({cfg}). ".format(
                v = ctx.attr.version,
                abi = abi,
                cfg = ctx.attr.config,
            ) +
            "Pass it explicitly, e.g. sha256 = {\"%s\": \"<digest>\"}." % abi,
        )

    # Extract under kit/ so the tree has a stable label prefix; the archive
    # itself has the runtime at its root.
    ctx.download_and_extract(
        url = packman_url("kit-kernel", version),
        sha256 = sha256,
        output = "kit",
        type = "zip",
    )

    # Kit embeds CPython and compiles its own stdlib on first import, writing
    # __pycache__ directories back into the tree -- that is, into this
    # repository, which Bazel then reports as modified externally and refetches.
    # The interpreter is configured by carbonite rather than from the
    # environment, so PYTHONDONTWRITEBYTECODE does not reach it; taking write
    # permission away does. CPython treats an unwritable cache directory as a
    # cache miss, which is exactly right for a tree Bazel owns.
    result = ctx.execute(["chmod", "-R", "a-w", "kit"])
    if result.return_code != 0:
        fail("could not make the Kit kernel tree read-only: %s" % result.stderr)

    ctx.file("BUILD.bazel", _KERNEL_BUILD.format(
        cc_library_bzl = ctx.attr.cc_library_bzl,
        gsl_label = ctx.attr.gsl,
        kit_executable = ctx.attr.kit_executable,
    ))

kit_kernel_repository = repository_rule(
    implementation = _kit_kernel_repository_impl,
    attrs = {
        "abi": attr.string(
            doc = "Override the detected packman platform_target_abi.",
        ),
        "cc_library_bzl": attr.string(
            mandatory = True,
            doc = "Canonical label of rules_cc's cc_library.bzl, which this " +
                  "repository's BUILD file loads.",
        ),
        "config": attr.string(
            default = "release",
            doc = "Kit build config: release or debug.",
        ),
        "gsl": attr.string(
            mandatory = True,
            doc = "Canonical label of the GSL headers target the generated " +
                  "sdk_headers library depends on.",
        ),
        "kit_executable": attr.string(
            default = "kit",
            doc = "Kit executable name inside the archive.",
        ),
        "sha256": attr.string_dict(
            doc = "Archive digests keyed by platform_target_abi. Optional for " +
                  "versions listed in KNOWN_KIT_KERNEL_SHA256.",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "kit-kernel package version, e.g. \"110.1.1+production\" -- " +
                  "what deps/kit-sdk.packman.xml pins.",
        ),
    },
    doc = "Downloads the prebuilt Omniverse Kit kernel Isaac Sim runs on.",
)

_EXT_BUILD = """\
load("{cc_library_bzl}", "cc_library")

package(default_visibility = ["//visibility:public"])
{libraries}
filegroup(
    name = "ext",
    visibility = ["//visibility:public"],
    srcs = glob(
        ["**"],
        exclude = ["BUILD.bazel", "WORKSPACE", "MODULE.bazel", "*.bzl"],
    ),
)
"""

_EXT_LIBRARY = """
# Linked against by name, the way the extension's premake5.lua names it. Kit
# loads its own copy at run time: this is only here to resolve symbols.
cc_library(
    name = "{name}",
    visibility = ["//visibility:public"],
    srcs = ["bin/{file}"],
)
"""

_EXT_ARCHIVE = """
# A static archive the package publishes for other extensions to link into
# themselves. Unlike the shared libraries beside it this is not something Kit
# loads, so it ends up inside whichever plugin names it.
cc_library(
    name = "{name}",
    visibility = ["//visibility:public"],
    srcs = ["bin/{file}"],
)
"""

def _kit_extension_repository_impl(ctx):
    ctx.download_and_extract(url = ctx.attr.url, sha256 = ctx.attr.sha256, type = "zip")

    # One target per shared library, so a native extension links against the
    # handful its sources name rather than everything the package happens to
    # carry -- a plugin that records a DT_NEEDED on ninety USD libraries it
    # never calls is a plugin whose load order now matters.
    libraries = []
    bin_dir = ctx.path("bin")
    if bin_dir.exists:
        for entry in bin_dir.readdir():
            name = entry.basename
            if name.startswith("lib") and name.endswith(".so"):
                libraries.append(_EXT_LIBRARY.format(
                    file = name,
                    name = name[len("lib"):-len(".so")],
                ))
            elif name.startswith("lib") and name.endswith(".a"):
                libraries.append(_EXT_ARCHIVE.format(
                    file = name,
                    name = name[len("lib"):-len(".a")],
                ))

    # Some prebuilt extensions publish interface headers of their own, which
    # the source of other extensions includes -- usdrt.scenegraph, for one.
    if ctx.path("include").exists:
        libraries.append("""
cc_library(
    name = "headers",
    visibility = ["//visibility:public"],
    hdrs = glob(["include/**"], allow_empty = True),
    includes = ["include"],
)
""")

    ctx.file("BUILD.bazel", _EXT_BUILD.format(
        cc_library_bzl = ctx.attr.cc_library_bzl,
        libraries = "".join(libraries),
    ))

kit_extension_repository = repository_rule(
    implementation = _kit_extension_repository_impl,
    attrs = {
        "cc_library_bzl": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True, doc = "Extension archive URL."),
    },
    doc = "Downloads one prebuilt Omniverse Kit extension package.",
)

_SDK_HEADERS_BUILD = """\
load("{cc_library_bzl}", "cc_library")

# Interface headers: the implementations are in the prebuilt extensions Kit
# loads at run time.
cc_library(
    name = "headers",
    visibility = ["//visibility:public"],
    hdrs = glob(["include/**"], allow_empty = True),
    includes = ["include"],
)

# Some of these packages also carry a Python payload that an extension vendors
# into itself rather than importing from elsewhere -- omni.sensors, for the RTX
# sensors. Empty for the header-only ones.
filegroup(
    name = "payload",
    visibility = ["//visibility:public"],
    srcs = glob(["omni/**"], allow_empty = True),
)
"""

def _sdk_headers_repository_impl(ctx):
    abi = ctx.attr.abi or target_abi(ctx)
    version = ctx.attr.version.format(abi = abi)
    sha256 = ctx.attr.sha256.get(abi, "")
    if not sha256:
        fail(
            "no sha256 known for {pkg} {v} on {abi}".format(
                abi = abi,
                pkg = ctx.attr.package,
                v = version,
            ),
        )

    # packman publishes most of these as 7z, which Bazel decompresses natively
    # (bazelbuild/bazel@93cd97e), but not all of them -- which one is per
    # package, so it is declared rather than guessed.
    ctx.download_and_extract(
        url = packman_url(ctx.attr.package, version, extension = ctx.attr.archive),
        sha256 = sha256,
        type = ctx.attr.archive,
    )
    ctx.file("BUILD.bazel", _SDK_HEADERS_BUILD.format(cc_library_bzl = ctx.attr.cc_library_bzl))

sdk_headers_repository = repository_rule(
    implementation = _sdk_headers_repository_impl,
    attrs = {
        "abi": attr.string(doc = "Override the detected platform_target_abi."),
        "archive": attr.string(
            default = "7z",
            doc = "Archive format the package is published in.",
        ),
        "cc_library_bzl": attr.string(mandatory = True),
        "package": attr.string(
            mandatory = True,
            doc = "packman package name, e.g. \"omni_physics\".",
        ),
        "sha256": attr.string_dict(
            mandatory = True,
            doc = "Archive digests keyed by platform_target_abi.",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "Package version, with {abi} where the platform goes.",
        ),
    },
    doc = "Downloads a packman package of interface headers and vendored payload.",
)

_WHEEL_BUILD = """\
filegroup(
    name = "files",
    visibility = ["//visibility:public"],
    srcs = glob(
        ["**"],
        exclude = ["BUILD.bazel", "WORKSPACE", "MODULE.bazel", "REPO.bazel"],
    ),
)
"""

def _pip_wheel_repository_impl(ctx):
    # A wheel is a zip; unpacking it is the whole of `pip install --target` for
    # the pure-Python ones a prebundle is allowed to hold.
    ctx.download_and_extract(url = ctx.attr.url, sha256 = ctx.attr.sha256, type = "zip")
    ctx.file("BUILD.bazel", _WHEEL_BUILD)

pip_wheel_repository = repository_rule(
    implementation = _pip_wheel_repository_impl,
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True, doc = "Wheel URL on PyPI."),
    },
    doc = "Downloads and unpacks one wheel of a pip prebundle.",
)

def _pip_prebundle_hub_repository_impl(ctx):
    wheels = [
        '        "@{repo}//:files",'.format(repo = repo)
        for repo in sorted(ctx.attr.wheels)
    ]
    ctx.file(
        "BUILD.bazel",
        """\
load("{impl}", "pip_prebundle")

# The site-packages directory the extension puts on sys.path.
pip_prebundle(
    name = "prebundle",
    visibility = ["//visibility:public"],
    wheels = [
{wheels}
    ],
)
""".format(impl = ctx.attr.pip_bzl, wheels = "\n".join(wheels)),
    )

pip_prebundle_hub_repository = repository_rule(
    implementation = _pip_prebundle_hub_repository_impl,
    attrs = {
        "pip_bzl": attr.string(
            mandatory = True,
            doc = "Canonical label of //bazel:pip.bzl.",
        ),
        "wheels": attr.string_list(
            mandatory = True,
            doc = "Repository names of the unpacked wheels.",
        ),
    },
    doc = "Gathers a prebundle's wheels into one directory target.",
)

def _kit_extension_hub_repository_impl(ctx):
    # The hub is where the packageId -> repository mapping becomes a Bazel
    # target: only here can both sides be named, because a repo generated by a
    # module extension may refer to its siblings by their declared names, which
    # nothing outside the extension can do.
    packages = [
        '        "@{repo}//:ext": "{package_id}",'.format(repo = repo, package_id = package_id)
        for package_id, repo in sorted(ctx.attr.packages.items())
    ]

    # The OmniGraph node generator is itself a prebuilt extension. It finds the
    # ABI version it generates against by looking for a directory named
    # omni.graph.core* beside its own, and its type configuration by walking up
    # to a directory named omni.graph.tools -- both by *resolved* path, so a
    # symlink farm will not do. kit_ogn_toolchain copies the two into one tree.
    ogn = ""
    if ctx.attr.ogn_tools_repo and ctx.attr.ogn_core_repo:
        ogn = """
# The OmniGraph node generator, laid out the way it expects to find itself.
kit_ogn_toolchain(
    name = "ogn_toolchain",
    visibility = ["//visibility:public"],
    core = "@{core}//:ext",
    tools = "@{tools}//:ext",
)
""".format(core = ctx.attr.ogn_core_repo, tools = ctx.attr.ogn_tools_repo)

    ctx.file(
        "BUILD.bazel",
        """\
load("{impl}", "kit_prebuilt_ext_folder")
load("{ogn_impl}", "kit_ogn_toolchain")

# Every pinned extension, laid out under one runfiles directory that Kit takes
# as a single --ext-folder.
kit_prebuilt_ext_folder(
    name = "ext_folder",
    visibility = ["//visibility:public"],
    packages = {{
{packages}
    }},
)
{ogn}""".format(
            impl = ctx.attr.ext_folder_bzl,
            ogn = ogn,
            ogn_impl = ctx.attr.ogn_bzl,
            packages = "\n".join(packages),
        ),
    )

kit_extension_hub_repository = repository_rule(
    implementation = _kit_extension_hub_repository_impl,
    attrs = {
        "ext_folder_bzl": attr.string(
            mandatory = True,
            doc = "Canonical label of //bazel:ext_folder.bzl, which this " +
                  "repository's BUILD file loads.",
        ),
        "ogn_bzl": attr.string(
            mandatory = True,
            doc = "Canonical label of //bazel:ogn.bzl.",
        ),
        "ogn_core_repo": attr.string(
            doc = "Repository holding the omni.graph.core package, if locked.",
        ),
        "ogn_tools_repo": attr.string(
            doc = "Repository holding the omni.graph.tools package, if locked.",
        ),
        "packages": attr.string_dict(
            mandatory = True,
            doc = "Registry packageId -> extension repository name.",
        ),
    },
    doc = "Aggregates the downloaded Kit extensions into one --ext-folder.",
)
