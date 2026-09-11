"""Module extension for the closed Omniverse Kit pieces Isaac Sim runs on.

`kit.prebundle()` fetches the PyPI wheels some extensions expect to find
vendored in a `pip_prebundle` directory.

`kit.kernel()` fetches the Kit kernel -- the runtime Isaac Sim is an application
on, and the exact package `deps/kit-sdk.packman.xml` pins. `kit.extensions()`
fetches the `omni.*` extensions that ship only as prebuilts (the RTX renderer,
omni.graph, omni.physx, ...), pinned in a JSON lock.

Both are declared by this module for its own targets; a consumer does not need
to repeat them. Both are lazy: a build that only uses the source-built
`isaacsim.*` extensions (`@isaacsim//:extensions`) downloads neither.
"""

load("//bazel:native_exts.bzl", "ISAACSIM_NATIVE_PLUGINS")
load("//bazel:source_exts.bzl", "ISAACSIM_SOURCE_EXTS")
load(
    "//bazel/private:kit_repo.bzl",
    "kit_extension_hub_repository",
    "kit_extension_repository",
    "kit_kernel_repository",
    "pip_prebundle_hub_repository",
    "pip_wheel_repository",
    "sdk_headers_repository",
    "target_abi",
)

def _ext_repo_name(hub_name, extension_name):
    return "{hub}_{ext}".format(
        hub = hub_name,
        ext = extension_name.replace(".", "_").replace("-", "_"),
    )

def _kit_impl(module_ctx):
    cc_library_bzl = str(Label("@rules_cc//cc:cc_library.bzl"))
    gsl = str(Label("@gsl//:gsl"))
    for mod in module_ctx.modules:
        for tag in mod.tags.kernel:
            kit_kernel_repository(
                name = tag.name,
                abi = tag.abi,
                # Canonical, because the generated BUILD file loads it from a
                # repository whose own mapping is not this module's.
                cc_library_bzl = cc_library_bzl,
                config = tag.config,
                gsl = gsl,
                kit_executable = tag.kit_executable,
                sha256 = tag.sha256,
                version = tag.version,
            )

        for tag in mod.tags.extensions:
            lock = json.decode(module_ctx.read(tag.lock))
            packages = {}
            ogn_repos = {}
            for package_id, spec in lock.items():
                # An extension built from source is not also downloaded. The
                # lock records what the app resolves to; which half of it is
                # ours to build is decided here, in one place, so the two can
                # never both offer the same package to Kit.
                if spec["name"] in ISAACSIM_SOURCE_EXTS or \
                   spec["name"] in ISAACSIM_NATIVE_PLUGINS:
                    continue

                repo = _ext_repo_name(tag.name, spec["name"])
                kit_extension_repository(
                    name = repo,
                    cc_library_bzl = cc_library_bzl,
                    sha256 = spec["sha256"],
                    url = spec["url"],
                )
                packages[package_id] = repo
                if spec["name"] in ("omni.graph.core", "omni.graph.tools"):
                    ogn_repos[spec["name"]] = repo

            kit_extension_hub_repository(
                name = tag.name,
                # Canonical, because the generated BUILD file loads these from a
                # repository whose own mapping is not this module's.
                ext_folder_bzl = str(Label("//bazel:ext_folder.bzl")),
                ogn_bzl = str(Label("//bazel:ogn.bzl")),
                ogn_core_repo = ogn_repos.get("omni.graph.core", ""),
                ogn_tools_repo = ogn_repos.get("omni.graph.tools", ""),
                packages = packages,
            )

        for tag in mod.tags.sdk_headers:
            sdk_headers_repository(
                name = tag.name,
                abi = tag.abi,
                archive = tag.archive,
                cc_library_bzl = cc_library_bzl,
                package = tag.package,
                sha256 = tag.sha256,
                version = tag.version,
            )

        for tag in mod.tags.prebundle:
            lock = json.decode(module_ctx.read(tag.lock))
            abi = target_abi(module_ctx)
            wheels = []
            for filename, spec in lock.items():
                if filename == "//":  # the lock's own provenance
                    continue

                # A wheel with no platform is universal; one with a platform
                # belongs to that host only. Picking here rather than with a
                # select() matches how the kernel package is chosen, and keeps
                # a prebundle what it is on disk: one directory.
                if spec.get("platform", abi) != abi:
                    continue
                repo = "{hub}_{pkg}".format(
                    hub = tag.name,
                    pkg = spec["name"].replace("-", "_").replace(".", "_"),
                )
                pip_wheel_repository(
                    name = repo,
                    sha256 = spec["sha256"],
                    url = spec["url"],
                )
                wheels.append(repo)

            pip_prebundle_hub_repository(
                name = tag.name,
                pip_bzl = str(Label("//bazel:pip.bzl")),
                wheels = wheels,
            )

    return module_ctx.extension_metadata(reproducible = True)

_kernel = tag_class(
    attrs = {
        "abi": attr.string(
            doc = "Override the detected packman platform_target_abi, e.g. " +
                  "\"manylinux_2_35_x86_64\".",
        ),
        "config": attr.string(
            default = "release",
            doc = "Kit build config: release or debug.",
        ),
        "kit_executable": attr.string(
            default = "kit",
            doc = "Kit executable name inside the archive.",
        ),
        "name": attr.string(
            default = "isaacsim_kit_kernel",
            doc = "Generated repository name.",
        ),
        "sha256": attr.string_dict(
            doc = "Archive digests keyed by platform_target_abi. May be omitted " +
                  "for the kernel versions this module already pins.",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "kit-kernel package version, e.g. \"110.1.1+production\".",
        ),
    },
    doc = "Downloads the prebuilt Kit kernel for the host platform.",
)

_extensions = tag_class(
    attrs = {
        "lock": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "JSON lock mapping registry packageId -> {name, url, sha256}.",
        ),
        "name": attr.string(
            default = "isaacsim_kit_exts",
            doc = "Name of the generated hub repository.",
        ),
    },
    doc = "Downloads the prebuilt-only Kit extensions listed in a JSON lock.",
)

_prebundle = tag_class(
    attrs = {
        "lock": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "JSON lock written by //bazel:gen_pip_lock.py.",
        ),
        "name": attr.string(
            mandatory = True,
            doc = "Name of the generated hub repository.",
        ),
    },
    doc = "Downloads the PyPI wheels an extension expects in its pip_prebundle.",
)

_sdk_headers = tag_class(
    attrs = {
        "abi": attr.string(doc = "Override the detected platform_target_abi."),
        "archive": attr.string(
            default = "7z",
            doc = "Archive format the package is published in: 7z or zip.",
        ),
        "name": attr.string(mandatory = True, doc = "Generated repository name."),
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
    doc = "Downloads a packman package of interface headers the C++ sources need.",
)

kit = module_extension(
    implementation = _kit_impl,
    tag_classes = {
        "extensions": _extensions,
        "kernel": _kernel,
        "prebundle": _prebundle,
        "sdk_headers": _sdk_headers,
    },
    doc = "The closed Omniverse Kit runtime and extensions Isaac Sim needs.",
)
