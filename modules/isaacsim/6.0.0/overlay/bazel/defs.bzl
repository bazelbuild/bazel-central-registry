"""Public API: build Isaac Sim's extensions from source and launch Kit apps.

    load("@isaacsim//bazel:defs.bzl", "isaacsim_kit_binary", "isaacsim_kit_test")

    isaacsim_kit_binary(name = "sim")                 # the stock Isaac Sim app
    isaacsim_kit_binary(name = "sdg", exec_script = "scenario.py")

`isaacsim_source_extensions()` is what the module's own root BUILD file uses to
declare one target per source-built `isaacsim.*` extension; consumers normally
want `@isaacsim//:extensions` instead, which is all of them in one --ext-folder.
"""

load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("//bazel:ext_folder.bzl", "EXT_FOLDER_MARKER")
load("//bazel:native_exts.bzl", "ISAACSIM_NATIVE_PLUGINS")
load("//bazel:ogn.bzl", "isaacsim_ogn_codegen")
load("//bazel:source_exts.bzl", "ISAACSIM_NATIVE_EXTS", "ISAACSIM_SOURCE_EXTS")
load("//bazel:src_ext.bzl", "isaacsim_extension", "isaacsim_extension_folder")
load("//bazel/private:exec.bzl", _executable_file = "executable_file")

executable_file = _executable_file

# Canonical labels, so these resolve the same whether the caller is this module,
# a consumer that renamed the dependency, or the test module.
_RUN_KIT = Label("//bazel:run_kit")
_KIT_BIN = Label("@isaacsim_kit_kernel//:kit/kit")
_KIT_DIST = Label("@isaacsim_kit_kernel//:dist")
_PREBUILT_EXT_FOLDER = Label("@isaacsim_kit_exts//:ext_folder")
_SOURCE_EXTS = Label("//:extensions")
_DEFAULT_APP = Label("//:source/apps/isaacsim.exp.base.kit")

# The OmniGraph node generator and the interpreter it runs under. Public,
# because the hand-written C++ recipes in //BUILD.bazel need them too.
OGN_TOOLCHAIN = Label("@isaacsim_kit_exts//:ogn_toolchain")
OGN_CONFIG = Label("@isaacsim_kit_kernel//:ogn_config")
KIT_PYTHON = Label("@isaacsim_kit_kernel//:kit/python/bin/python3")
KIT_PYTHON_RUNTIME = Label("@isaacsim_kit_kernel//:python")

_OGN_TOOLCHAIN = OGN_TOOLCHAIN
_OGN_CONFIG = OGN_CONFIG
_KIT_PYTHON = KIT_PYTHON
_KIT_PYTHON_RUNTIME = KIT_PYTHON_RUNTIME

# The pip prebundles this module can build, by the packman target-dep name the
# extensions' premake refers to. The lula and cumotion bundles are absent on
# purpose: their wheels are NVIDIA-authored and not on PyPI.
_PIP_PREBUNDLES = {
    "isaac_newton_prebundle": Label("@isaacsim_pip_newton//:prebundle"),
    "isaac_urdf_usd_prebundle": Label("@isaacsim_pip_urdf_usd//:prebundle"),
}

# The packman packages whose payload an extension vendors into itself, by the
# target-dep directory its premake refers to. Closed, like the rest of the
# Omniverse sensor stack, and pinned in MODULE.bazel.
_PACKMAN_PAYLOADS = {
    "generic_model_output": Label("@isaacsim_generic_model_output//:payload"),
    "sensor-checker": Label("@isaacsim_sensor_checker//:payload"),
}

# Dependencies the shipped packages need but do not declare, and the settings
# that keep a run offline; see deps.kit and hermetic.kit.
_DEFAULT_MERGE_CONFIGS = [
    Label("//bazel:deps.kit"),
    Label("//bazel:hermetic.kit"),
]

def _rloc(label):
    return "$(rlocationpath %s)" % label

def _rloc_list(labels):
    return ":".join([_rloc(label) for label in labels]) if labels else "-"

def _kit_target(
        kit_rule,
        name,
        app,
        exec_script,
        ext_folders,
        prebuilts,
        merge_configs,
        expect_output,
        reject_output,
        kit_args,
        **kwargs):
    if app == None:
        app = _DEFAULT_APP
    if ext_folders == None:
        ext_folders = [_SOURCE_EXTS]
    if merge_configs == None:
        merge_configs = _DEFAULT_MERGE_CONFIGS

    data = [_KIT_BIN, _KIT_DIST, app] + ext_folders + merge_configs
    if exec_script:
        data.append(exec_script)

    # Order does not decide anything: the lock holds only extensions that cannot
    # be built from source, so the two folders never offer the same package.
    folders = []
    if prebuilts:
        data.append(_PREBUILT_EXT_FOLDER)
        folders.append(EXT_FOLDER_MARKER)
    folders += [_rloc(f) for f in ext_folders]

    kit_rule(
        name = name,
        srcs = [_RUN_KIT],
        args = [
            _rloc(_KIT_BIN),
            _rloc(app),
            _rloc(exec_script) if exec_script else "-",
            ":".join(folders) if folders else "-",
            _rloc_list(merge_configs),
            expect_output if expect_output else "-",
            reject_output if reject_output else "-",
        ] + kit_args,
        data = data,
        deps = [Label("@bazel_tools//tools/bash/runfiles")],
        **kwargs
    )

def isaacsim_kit_binary(
        name,
        app = None,
        exec_script = None,
        ext_folders = None,
        prebuilts = True,
        merge_configs = None,
        kit_args = [],
        **kwargs):
    """Launches a Kit app.

    Args:
        name: Target name.
        app: The .kit app config. Defaults to Isaac Sim's own
            source/apps/isaacsim.exp.base.kit.
        exec_script: Optional Python script for Kit to run once started
            (`kit --exec`), i.e. the scenario to simulate.
        ext_folders: Directories of extensions to offer Kit. Defaults to
            @isaacsim//:extensions, every isaacsim.* extension built from source.
        prebuilts: Whether to also offer the pinned closed-source Kit extensions.
            The stock app needs them; a kernel-only app does not.
        merge_configs: .kit fragments layered on with --merge-config. Defaults
            to @isaacsim//bazel:deps.kit and @isaacsim//bazel:hermetic.kit.
        kit_args: Extra arguments for Kit itself, e.g. ["--no-window"].
        **kwargs: Passed through to sh_binary.
    """
    _kit_target(
        sh_binary,
        name = name,
        app = app,
        exec_script = exec_script,
        ext_folders = ext_folders,
        prebuilts = prebuilts,
        merge_configs = merge_configs,
        expect_output = None,
        reject_output = None,
        kit_args = kit_args,
        **kwargs
    )

def isaacsim_kit_test(
        name,
        expect_output,
        reject_output = None,
        app = None,
        exec_script = None,
        ext_folders = None,
        prebuilts = True,
        merge_configs = None,
        kit_args = [],
        **kwargs):
    """Runs a Kit app and asserts a string appears in its output.

    Kit can exit non-zero while tearing down GPU state after an otherwise
    successful run, so the sentinel is what decides the test, not the exit code.

    Args:
        name: Target name.
        expect_output: String Kit must print for the test to pass. It is passed
            through `args`, which Bazel tokenizes, so it cannot contain spaces.
        reject_output: String whose presence fails the test -- "[Error]" for a
            run that is supposed to be clean.
        app: See isaacsim_kit_binary.
        exec_script: See isaacsim_kit_binary.
        ext_folders: See isaacsim_kit_binary.
        prebuilts: See isaacsim_kit_binary.
        merge_configs: See isaacsim_kit_binary.
        kit_args: See isaacsim_kit_binary.
        **kwargs: Passed through to sh_test.
    """
    _kit_target(
        sh_test,
        name = name,
        app = app,
        exec_script = exec_script,
        ext_folders = ext_folders,
        prebuilts = prebuilts,
        merge_configs = merge_configs,
        expect_output = expect_output,
        reject_output = reject_output,
        kit_args = kit_args,
        **kwargs
    )

def isaacsim_source_extension_target(extension_name):
    """Label of the source-built extension of that name.

    Args:
        extension_name: e.g. "isaacsim.replicator.behavior".

    Returns:
        A label string, relative to the module root package.
    """
    return ":" + extension_name

def isaacsim_source_extensions(name = "extensions"):
    """Declares every isaacsim.* extension that can be built from source.

    One target per extension, named after it, plus `name`: all of them merged
    into a single directory for Kit's --ext-folder.

    Args:
        name: Name of the merged --ext-folder target.
    """

    # Everything the generator found assemblable, plus the native extensions
    # that have a build recipe written for them.
    buildable = dict(ISAACSIM_SOURCE_EXTS)
    for ext in ISAACSIM_NATIVE_PLUGINS:
        buildable[ext] = ISAACSIM_NATIVE_EXTS[ext]

    for ext, spec in buildable.items():
        root = "source/{dir}/{ext}".format(dir = spec["dir"], ext = ext)
        srcs = native.glob([root + "/**"])

        # An extension with OmniGraph nodes needs its databases generated before
        # it is assembled, and the node definitions copied in beside them --
        # premake's ogn helpers do both, and neither shows up in the prebuild
        # rules that `mapping` comes from.
        ogn = spec.get("ogn")
        mapping = spec["mapping"]
        ogn_generated = None
        ogn_module = ""
        if ogn:
            ogn_module = ogn["module"]

            # Bazel checks each glob pattern for emptiness on its own, so the
            # directories are the ones the generator saw .ogn files in rather
            # than the two places they conventionally live.
            src_dirs = ogn["src_dirs"]
            if not src_dirs:
                fail("%s declares OmniGraph nodes but has no .ogn files" % ext)
            ogn_files = native.glob(
                ["{root}/{dir}/*.ogn".format(root = root, dir = d) for d in src_dirs],
            )

            isaacsim_ogn_codegen(
                name = ext + ".ogn",
                config = _OGN_CONFIG,
                extension_name = ext,
                module = ogn_module,
                # A .ogn lives either in a directory add_ogn_dependencies
                # names -- python/nodes, for Python nodes -- or in nodes/,
                # premake's default for C++ ones. An extension can have both.
                node_srcs = native.glob(
                    ["{root}/{dir}/**".format(root = root, dir = d) for d in src_dirs],
                ),
                ogn_files = ogn_files,
                python = _KIT_PYTHON,
                python_runtime = _KIT_PYTHON_RUNTIME,
                toolchain = _OGN_TOOLCHAIN,
            )
            ogn_generated = ":" + ext + ".ogn"

        isaacsim_extension(
            name = ext,
            visibility = ["//visibility:public"],
            srcs = srcs,
            extension_name = ext,
            mapping = mapping,
            ogn_generated = ogn_generated,
            ogn_module = ogn_module,
            ogn_node_dirs = ogn["node_dirs"] if ogn else [],
            payloads = {
                _PACKMAN_PAYLOADS[package]: destination
                for package, destination in spec.get("payloads", {}).items()
            },
            pip_prebundle = _PIP_PREBUNDLES.get(spec.get("pip_prebundle", "")),
            native_artifacts = ISAACSIM_NATIVE_PLUGINS.get(ext, {}),
        )

    isaacsim_extension_folder(
        name = name,
        visibility = ["//visibility:public"],
        exts = [isaacsim_source_extension_target(ext) for ext in buildable],
    )
