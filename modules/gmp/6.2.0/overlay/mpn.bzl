load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_m4//m4:m4.bzl", "M4_TOOLCHAIN_TYPE", "m4_toolchain")

alternatives = {
    "add_err1_n": ["aors_err1_n"],
    "add_err2_n": ["aors_err2_n"],
    "add_err3_n": ["aors_err3_n"],
    "add_n": ["aors_n"],
    "addlsh1_n": ["aorslsh1_n", "aorrlsh1_n", "aorsorrlsh1_n"],
    "addlsh2_n": ["aorslsh2_n", "aorrlsh2_n", "aorsorrlsh2_n"],
    "addlsh_n": ["aorslsh_n", "aorrlsh_n", "aorsorrlsh_n"],
    "addmul_1": ["aorsmul_1"],
    "addmul_2": ["aormul_2"],
    "addmul_3": ["aormul_3"],
    "addmul_4": ["aormul_4"],
    "and_n": ["logops_n"],
    "andn_n": ["logops_n"],
    "cnd_add_n": ["cnd_aors_n"],
    "cnd_sub_n": ["cnd_aors_n"],
    "hamdist": ["popham"],
    "ior_n": ["logops_n"],
    "iorn_n": ["logops_n"],
    "lshift": ["lorrshift"],
    "mul_2": ["aormul_2"],
    "mul_3": ["aormul_3"],
    "mul_4": ["aormul_4"],
    "nand_n": ["logops_n"],
    "nior_n": ["logops_n"],
    "popcount": ["popham"],
    "rsblsh1_n": ["aorrlsh1_n", "sorrlsh1_n", "aorsorrlsh1_n"],
    "rsblsh2_n": ["aorrlsh2_n", "sorrlsh2_n", "aorsorrlsh2_n"],
    "rsblsh_n": ["aorrlsh_n", "sorrlsh_n", "aorsorrlsh_n"],
    "rsh1add_n": ["rsh1aors_n"],
    "rsh1sub_n": ["rsh1aors_n"],
    "rshift": ["lorrshift"],
    "sec_add_1": ["sec_aors_1"],
    "sec_div_qr": ["sec_div"],
    "sec_div_r": ["sec_div"],
    "sec_pi1_div_qr": ["sec_pi1_div"],
    "sec_pi1_div_r": ["sec_pi1_div"],
    "sec_sub_1": ["sec_aors_1"],
    "sub_err1_n": ["aors_err1_n"],
    "sub_err2_n": ["aors_err2_n"],
    "sub_err3_n": ["aors_err3_n"],
    "sub_n": ["aors_n"],
    "sublsh1_n": ["aorslsh1_n", "sorrlsh1_n", "aorsorrlsh1_n"],
    "sublsh2_n": ["aorslsh2_n", "sorrlsh2_n", "aorsorrlsh2_n"],
    "sublsh_n": ["aorslsh_n", "sorrlsh_n", "aorsorrlsh_n"],
    "submul_1": ["aorsmul_1"],
    "xnor_n": ["logops_n"],
    "xor_n": ["logops_n"],
}

def current_directory():
    repo_name = native.repository_name()
    if repo_name.startswith("@@"):
        repo_name = repo_name[2:]
    elif repo_name.startswith("@"):
        repo_name = repo_name[1:]

    if repo_name == "":
        return native.package_name()
    else:
        return "external/" + repo_name + "/" + native.package_name()

def mpn_cc_library(
        name,
        srcs,
        hdrs = [],
        copts = [],
        deps = [],
        target_compatible_with = None):
    cc_library(
        name = name,
        srcs = srcs,
        hdrs = hdrs,
        copts = copts + [
            "-DHAVE_CONFIG_H",
            "-I" + current_directory() + "/mpn",
            "-I" + current_directory(),
            "-I$(GENDIR)/" + current_directory(),
            "-D__GMP_WITHIN_GMP",
            "-DOPERATION_" + name,
        ],
        deps = deps,
        target_compatible_with = target_compatible_with,
    )

def _m4_mpn_function_impl(ctx):
    m4 = m4_toolchain(ctx)
    if len(ctx.files.files) == 0:
        out = ctx.actions.declare_file("mpn/" + ctx.attr.operation + ".c")
        ctx.actions.write(out, "")
        return DefaultInfo(files = depset([out]))

    if ctx.files.files[0].extension == "c":
        out = ctx.actions.declare_file("mpn/" + ctx.attr.operation + ".c")
        ctx.actions.run_shell(
            inputs = [ctx.files.files[0]],
            outputs = [out],
            progress_message = "Generating " + out.short_path,
            command = "(echo '#define OPERATION_" + ctx.attr.operation + " 1'; cat " + ctx.files.files[0].path + ") > " + out.path,
        )
        return DefaultInfo(files = depset([out]))

    out = ctx.actions.declare_file("mpn/" + ctx.attr.operation + ".s")

    ruledir = ctx.label.workspace_root + "/" + ctx.label.package
    ctx.actions.run_shell(
        inputs = [ctx.files.files[0]] + ctx.files.deps,
        outputs = [out],
        progress_message = "Generating " + out.short_path,
        tools = [m4.m4_tool],
        env = m4.m4_env,
        command = " && ".join([
            "ROOT=$(pwd)",
            "cd ./" + ruledir + "/mpn",
            "echo '#define OPERATION_" + ctx.attr.operation + " 1' > ${ROOT}/" + out.path,
            "${ROOT}/" + m4.m4_tool.executable.path + " -I ${ROOT}/" + ctx.var["GENDIR"] + "/" + ruledir + "/mpn" +
            " -DHAVE_CONFIG_H -D__GMP_WITHIN_GMP -DOPERATION_" + ctx.attr.operation +
            " -DPIC ${ROOT}/" + ctx.files.files[0].path + " >> ${ROOT}/" + out.path,
        ]),
    )

    return DefaultInfo(files = depset([out]))

_m4_mpn_function = rule(
    attrs = {
        "deps": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
        "files": attr.label_list(
            allow_files = True,
        ),
        "operation": attr.string(
            mandatory = True,
        ),
    },
    implementation = _m4_mpn_function_impl,
    toolchains = [M4_TOOLCHAIN_TYPE],
)

def mparam_path(architecture_paths):
    result = dict()
    for key in architecture_paths:
        value = architecture_paths[key]
        globs = []
        for p in value:
            globs += native.glob([
                "mpn/" + p + "/gmp-mparam.h",
            ])
        result[key] = [globs[0]]

    return select(result)

def architecture_includes(architecture_paths):
    result = dict()
    for key in architecture_paths:
        result[key] = ["-I" + current_directory() + "/mpn/" + p for p in architecture_paths[key]]
    return select(result)

def file_from_architecture(architecture_paths, f):
    result = dict()
    for key in architecture_paths:
        result[key] = ["config/" + architecture_paths[key][0] + "/" + f]
    return select(result)

def config_include_from_architecture(architecture_paths):
    result = dict()
    for key in architecture_paths:
        result[key] = ["-I" + current_directory() + "/config/" + architecture_paths[key][0] + "/"]
    return select(result)

def _file_globs(path, use_asm):
    if use_asm:
        return native.glob([
            path + ".asm",
            path + ".c",
        ])
    else:
        return native.glob([
            path + ".c",
        ])

def mpn_m4_cc_library(name, architecture_paths, target_compatible_with = None):
    # Search architecture_paths in order from 0 to N.
    # From there, search starting with the main name, then start looking at the alternatives.
    # And then look for .c or .asm
    architecture_globs = dict()
    for key in architecture_paths:
        value = architecture_paths[key]
        globs = []
        for p in value:
            globs += _file_globs("mpn/" + p + "/" + name, "msan" not in key)
            if name in alternatives:
                for alternative in alternatives[name]:
                    globs += _file_globs("mpn/" + p + "/" + alternative, "msan" not in key)
        architecture_globs[key] = globs

    _m4_mpn_function(
        name = name,
        operation = name,
        files = select(architecture_globs),
        deps = native.glob(["**/*.m4", "**/*.asm"]) + ["config.m4"],
        target_compatible_with = target_compatible_with,
    )
