"""Native Bazel build of the ngspice 47 XSPICE code-model modules.

The caller supplies the target-platform config.h as a cc_library dependency.
cmpp runs in the execution configuration and needs no simulator config.h.
"""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load(":xspice_sources.bzl", "CMPP_SOURCES", "CODE_MODELS")

visibility("//...")

_REGISTRY_OUTPUTS = [
    "cmextrn.h",
    "cminfo.h",
    "cminfo2.h",
    "udnextrn.h",
    "udninfo.h",
    "udninfo2.h",
    "objects.inc",
]

def _cmpp_generate_impl(ctx):
    output_names = {
        "ifs": ["ifspec.c"],
        "mod": ["cfunc.c"],
        "lst": _REGISTRY_OUTPUTS,
    }[ctx.attr.mode]
    outputs = [ctx.actions.declare_file(ctx.attr.output_dir + "/" + filename) for filename in output_names]
    arguments = ["-" + ctx.attr.mode]
    if ctx.attr.mode == "mod":
        arguments.append(ctx.file.entrypoint.basename)
    ctx.actions.run(
        executable = ctx.executable.cmpp,
        arguments = arguments,
        inputs = depset([ctx.file.entrypoint] + ctx.files.inputs),
        outputs = outputs,
        env = {
            "CMPP_IDIR": ctx.file.entrypoint.dirname,
            "CMPP_ODIR": outputs[0].dirname,
        },
        mnemonic = "XspiceCmpp",
        progress_message = "Generating XSPICE %s files for %s" % (ctx.attr.mode, ctx.label),
    )
    return [DefaultInfo(files = depset(outputs))]

cmpp_generate = rule(
    implementation = _cmpp_generate_impl,
    attrs = {
        "cmpp": attr.label(executable = True, cfg = "exec", mandatory = True),
        "entrypoint": attr.label(allow_single_file = True, mandatory = True),
        "inputs": attr.label_list(allow_files = True),
        "mode": attr.string(values = ["ifs", "mod", "lst"], mandatory = True),
        "output_dir": attr.string(mandatory = True),
    },
)

def _code_model_file_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output = output, target_file = ctx.file.binary)
    return [DefaultInfo(
        files = depset([output]),
        runfiles = ctx.runfiles(files = [output, ctx.file.binary]),
    )]

_code_model_file = rule(
    implementation = _code_model_file_impl,
    attrs = {"binary": attr.label(allow_single_file = True, mandatory = True)},
)

def ngspice_code_models(name, config, source_root = "src", visibility = None, target_compatible_with = []):
    """Build all seven dlopen-able .cm files with the C++ toolchain.

    Args:
      name: Filegroup exposing the modules; outputs are name/<family>.cm.
      config: cc_library exposing ngspice/config.h for the TARGET platform.
      source_root: Source tree path within this package (normally "src").
      visibility: Visibility of the filegroup and each loadable module.
      target_compatible_with: Constraints for the target modules, not cmpp.
    """
    prefix = name + "_"
    cmpp_dir = source_root + "/xspice/cmpp"
    icm_dir = source_root + "/xspice/icm"
    tlines_dir = source_root + "/xspice/tlines"

    cc_binary(
        conlyopts = ["-std=gnu11"],
        name = prefix + "cmpp",
        srcs = [cmpp_dir + "/" + filename for filename in CMPP_SOURCES] + native.glob([cmpp_dir + "/*.h"]),
        visibility = ["//visibility:private"],
    )
    cc_library(
        conlyopts = ["-std=gnu11"],
        name = prefix + "headers",
        hdrs = [icm_dir + "/dlmain.h"] + native.glob([
            source_root + "/include/ngspice/*.h",
            source_root + "/maths/dense/*.h",
        ]),
        includes = [source_root + "/include"],
        deps = [config],
        visibility = ["//visibility:private"],
    )
    cc_library(
        conlyopts = ["-std=gnu11"],
        name = prefix + "common",
        srcs = [
            source_root + "/misc/dstring.c",
            tlines_dir + "/msline_common.c",
            tlines_dir + "/tline_common.c",
        ],
        hdrs = native.glob([tlines_dir + "/*.h"]),
        includes = [tlines_dir],
        copts = ["-fvisibility=hidden"],
        deps = [":" + prefix + "headers"],
        visibility = ["//visibility:private"],
        target_compatible_with = target_compatible_with,
    )

    modules = []
    for family, manifest in CODE_MODELS.items():
        family_dir = icm_dir + "/" + family
        generated_dir = name + "_generated/" + family
        registry = prefix + family + "_registry"

        # -lst reads every ifspec.ifs and UDN source in addition to both lists.
        cmpp_generate(
            name = registry,
            cmpp = ":" + prefix + "cmpp",
            mode = "lst",
            entrypoint = family_dir + "/modpath.lst",
            inputs = [family_dir + "/udnpath.lst"] + [
                family_dir + "/" + model + "/ifspec.ifs"
                for model in manifest["models"]
            ] + [
                family_dir + "/" + udn + "/udnfunc.c"
                for udn in manifest["udns"]
            ],
            output_dir = generated_dir,
            visibility = ["//visibility:private"],
        )
        cc_library(
            conlyopts = ["-std=gnu11"],
            name = prefix + family + "_headers",
            hdrs = [":" + registry] + native.glob([family_dir + "/**/*.h"], allow_empty = True),
            # table3D includes these C implementations textually; do not compile
            # them again or expose a generated-tree sibling by undeclared access.
            textual_hdrs = native.glob(
                [family_dir + "/mada/*.c", family_dir + "/support/*.c"],
                allow_empty = True,
            ),
            includes = [family_dir, generated_dir],
            deps = [":" + prefix + "headers"],
            visibility = ["//visibility:private"],
            target_compatible_with = target_compatible_with,
        )
        model_deps = []
        for model in manifest["models"]:
            model_dir = family_dir + "/" + model
            model_name = prefix + family + "_" + model
            for mode, entrypoint in [("ifs", "ifspec.ifs"), ("mod", "cfunc.mod")]:
                cmpp_generate(
                    name = model_name + "_" + mode,
                    cmpp = ":" + prefix + "cmpp",
                    mode = mode,
                    entrypoint = model_dir + "/" + entrypoint,
                    # -mod also reads its model's interface specification.
                    inputs = [model_dir + "/ifspec.ifs"],
                    output_dir = generated_dir + "/" + model,
                    visibility = ["//visibility:private"],
                )
            cc_library(
                conlyopts = ["-std=gnu11"],
                name = model_name,
                srcs = [":" + model_name + "_ifs", ":" + model_name + "_mod"],
                # The generated code keeps relative textual includes from the
                # original model directory. Materialize that declared directory
                # in the compile sandbox, even for models with no local headers.
                additional_compiler_inputs = [model_dir + "/cfunc.mod"],
                includes = [model_dir],
                copts = ["-fvisibility=hidden"],
                deps = [
                    ":" + prefix + family + "_headers",
                    ":" + prefix + "common",
                ],
                visibility = ["//visibility:private"],
                target_compatible_with = target_compatible_with,
            )
            model_deps.append(":" + model_name)

        module = name + "/" + family + ".cm"
        cc_binary(
            conlyopts = ["-std=gnu11"],
            name = prefix + family + "_module",
            srcs = [icm_dir + "/dlmain.c"] + [
                family_dir + "/" + udn + "/udnfunc.c"
                for udn in manifest["udns"]
            ],
            copts = ["-fvisibility=hidden"],
            linkshared = True,
            linkstatic = True,
            linkopts = select({
                "@platforms//os:linux": ["-lm", "-ldl", "-Wl,--no-undefined"],
                "//conditions:default": [],
            }),
            deps = model_deps + [
                ":" + prefix + family + "_headers",
                ":" + prefix + "common",
            ],
            visibility = visibility,
            target_compatible_with = target_compatible_with,
        )

        # Native cc_binary chooses a platform suffix (.so/.dylib). Publish the
        # upstream .cm basename as a declared output, preserving both runfiles.
        _code_model_file(
            name = module,
            binary = ":" + prefix + family + "_module",
            visibility = visibility,
            target_compatible_with = target_compatible_with,
        )
        modules.append(":" + module)
    native.filegroup(
        name = name,
        srcs = modules,
        visibility = visibility,
        target_compatible_with = target_compatible_with,
    )

def ngspice_cosimulation_modules(name, config, source_root = "src", visibility = None, target_compatible_with = []):
    """Build upstream's Icarus shim and VPI module without an Icarus dependency.

    The VPI module intentionally resolves its simulator API in the loading
    Icarus process. The other XSPICE modules do not need dynamic symbol lookup.

    Args:
      name: Filegroup exposing ivlng.so and ivlng.vpi below this output directory.
      config: cc_library exposing ngspice/config.h for the target platform.
      source_root: Source tree path within this package (normally "src").
      visibility: Visibility of the filegroup and each loadable module.
      target_compatible_with: Constraints for the target modules.
    """
    verilog = source_root + "/xspice/verilog"
    cc_library(
        conlyopts = ["-std=gnu11"],
        name = name + "_headers",
        hdrs = native.glob([
            source_root + "/include/ngspice/*.h",
            verilog + "/*.h",
        ]),
        includes = [source_root + "/include", verilog],
        deps = [config],
        visibility = ["//visibility:private"],
        target_compatible_with = target_compatible_with,
    )
    modules = []
    for filename, source in [("ivlng.so", "icarus_shim.c"), ("ivlng.vpi", "vpi.c")]:
        native_name = name + "_" + source[:-2]
        cc_binary(
            conlyopts = ["-std=gnu11"],
            name = native_name,
            srcs = [verilog + "/" + source],
            deps = [":" + name + "_headers"],
            linkshared = True,
            linkstatic = True,
            linkopts = select({
                "@platforms//os:linux": ["-lm", "-lpthread", "-ldl"],
                "@platforms//os:macos": ["-Wl,-undefined,dynamic_lookup"] if source == "vpi.c" else [],
                "//conditions:default": [],
            }),
            visibility = ["//visibility:private"],
            target_compatible_with = target_compatible_with,
        )
        module = name + "/" + filename
        _code_model_file(
            name = module,
            binary = ":" + native_name,
            visibility = visibility,
            target_compatible_with = target_compatible_with,
        )
        modules.append(":" + module)
    native.filegroup(
        name = name,
        srcs = modules,
        visibility = visibility,
        target_compatible_with = target_compatible_with,
    )
