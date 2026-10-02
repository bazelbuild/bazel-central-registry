# Copyright 2026 Open Source Robotics Foundation, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Adapted from https://github.com/bazelbuild/rules_rust/pull/392

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_rust//rust:rust_common.bzl", "CrateInfo", "DepInfo")
load(":cargo_manifest.bzl", "CargoManifestInfo", "cargo_manifest_aspect")

def _rust_cbindgen_library_impl(ctx):
    """'rust_cbindgen' rule implementation

    Args:
        ctx: A context object that is passed to the implementation function for a rule or aspect.
    Returns:
        (list) a list of Providers
    """

    rust_lib = ctx.attr.lib
    
    # Check if we have CrateInfo (rust_library) or just DepInfo (rust_shared_library/rust_static_library)
    has_crate_info = CrateInfo in rust_lib
    
    # If we have CrateInfo, validate crate type
    if has_crate_info:
        supported_crate_types = ["cdylib", "staticlib"]
        if not rust_lib[CrateInfo].type in supported_crate_types:
            fail("Rust library '{}' of type '{}' must be one of {}".format(
                rust_lib.label,
                rust_lib[CrateInfo].type,
                supported_crate_types,
            ))

    # Determine the location of the cbindgen executable
    toolchain = ctx.toolchains["//cbindgen:cbindgen_toolchain"]
    cbindgen_bin = toolchain.cbindgen

    # Optionally use the user defined template if one is provided
    if ctx.file.config:
        template_config = ctx.file.config
        substitutions = ctx.attr.substitutions
    else:
        if ctx.attr.substitutions:
            fail("'substitutions' should not be defined without the `config` attribute also being defined.")

        # Identify the desired language
        use_c = ctx.attr.lang in ["c"]
        use_cpp = ctx.attr.lang in ["cc", "c++", "cxx"]

        if use_c and use_cpp:
            fail("The use of C/C++ must be mutually exclusive")

        template_config = ctx.file._config_default_template

        # Direct dependents
        substitutions = {
            "{label}": str(ctx.label),
            "{language}": "C" if use_c else "C++",
            "{include_guard}": "INCLUDE_{}_H".format(ctx.label.name.upper()),
            "{namespace}": "namespace = \"{}\"".format(ctx.label.name) if use_cpp else "",
        }

    # Generate the `cbindgen.toml` config file
    ctx.actions.expand_template(
        template = template_config,
        output = ctx.outputs.config,
        substitutions = substitutions,
    )

    output_header = ctx.actions.declare_file(
        ctx.attr.header_name if ctx.attr.header_name else "{}.h".format(ctx.label.name),
    )

    args = ctx.actions.args()
    args.add("--config")
    args.add(ctx.outputs.config)
    args.add("--output")
    args.add(output_header)
    args.add(rust_lib[CargoManifestInfo].toml.dirname)

    # Build inputs - handle both CrateInfo and DepInfo cases
    if has_crate_info:
        # Traditional case with rust_library
        input_srcs = rust_lib[CrateInfo].srcs
        dep_srcs = [
            depset(dep[CrateInfo].srcs)
            for dep in rust_lib[CrateInfo].deps
            if CrateInfo in dep
        ]
    else:
        # For rust_shared_library/rust_static_library, get sources from the aspect
        input_srcs = []
        dep_srcs = []

    inputs = depset(
        input_srcs + [ctx.outputs.config],
        transitive = [
            rust_lib[OutputGroupInfo].all_files,
            depset(transitive = dep_srcs),
        ],
    )

    rust_toolchain = ctx.toolchains["@rules_rust//rust:toolchain"]
    
    # In newer rules_rust, exec_triple and target_triple are structs
    # with a .str field containing the actual triple string
    exec_triple = rust_toolchain.exec_triple.str if hasattr(rust_toolchain.exec_triple, 'str') else str(rust_toolchain.exec_triple)
    target_triple = rust_toolchain.target_triple.str if hasattr(rust_toolchain.target_triple, 'str') else str(rust_toolchain.target_triple)
    
    env = {
        "CARGO": rust_toolchain.cargo.path,
        "HOST": exec_triple,
        "RUSTC": rust_toolchain.rustc.path,
        "TARGET": target_triple,
    }

    # Use all_files from the toolchain which contains all necessary files
    # This is more reliable than trying to access individual components
    # which may have different APIs across rules_rust versions
    tools = rust_toolchain.all_files

    ctx.actions.run(
        mnemonic = "RustCbindgen",
        progress_message = "Generating {} bindings for '{}'..".format(
            ctx.attr.lang.upper(),
            output_header.short_path,
        ),
        outputs = [output_header],
        executable = cbindgen_bin,
        inputs = inputs,
        arguments = [args],
        tools = tools,
        env = env,
    )

    rust_compilation_context = rust_lib[CcInfo].compilation_context

    # Add the new headers to the existing CompilationContext info
    compilation_context = cc_common.create_compilation_context(
        headers = depset([output_header], transitive = [rust_compilation_context.headers]),
        defines = rust_compilation_context.defines,
        framework_includes = rust_compilation_context.framework_includes,
        includes = rust_compilation_context.includes,
        local_defines = rust_compilation_context.local_defines,
        quote_includes = rust_compilation_context.quote_includes,
        system_includes = rust_compilation_context.system_includes,
    )

    # Return all providers given by `cc_library` and `rust_library` to ensure
    # compatiblity with other rules
    providers = [
        CcInfo(
            compilation_context = compilation_context,
            linking_context = rust_lib[CcInfo].linking_context,
        ),
        DefaultInfo(
            files = depset([output_header], transitive = [rust_lib.files]),
            runfiles = ctx.runfiles([output_header], transitive_files = rust_lib.files),
        ),
    ]
    
    # Only include CrateInfo and DepInfo if they exist
    if has_crate_info:
        providers.append(rust_lib[CrateInfo])
    if DepInfo in rust_lib:
        providers.append(rust_lib[DepInfo])
    
    return providers

rust_cbindgen_library = rule(
    implementation = _rust_cbindgen_library_impl,
    attrs = {
        "lib": attr.label(
            doc = (
                "The `rust_library` target from which to run cbindgen on. " +
                "The `crate_type` of the target passed here must be " +
                "either `cdylib` or `staticlib`."
            ),
            providers = [CcInfo],  # Support both rust_library (CrateInfo) and rust_shared_library (DepInfo)
            aspects = [cargo_manifest_aspect],
            mandatory = True,
        ),
        "cbindgen_flags": attr.string_list(
            doc = (
                "Optional flags to pass directly to the bindgen executable. " +
                "See https://docs.rs/cbindgen/latest/cbindgen/ for details."
            ),
        ),
        "header_name": attr.string(
            doc = (
                "Optional override for the name of the generated header. The default is the " +
                "name of the target created by this rule."
            ),
        ),
        "lang": attr.string(
            doc = "Optional target language identifier of the generated header file",
            values = [
                "c",
                "cc",
                "c++",
                "cxx",
            ],
            default = "cc",
        ),
        "config": attr.label(
            doc = "Optional Cbindgen configuration template",
            allow_single_file = True,
        ),
        "substitutions": attr.string_dict(
            doc = "Optional substitutions for the cbindgen config template passed to `config`",
        ),
        "_config_default_template": attr.label(
            doc = "Default cbindgen configuration template. This is treated as fallback from `config`",
            default = Label("//cbindgen:private/cbindgen.toml.template"),
            allow_single_file = True,
        ),
    },
    outputs = {
        "config": "%{name}.cbindgen.toml",
    },
    toolchains = [
        "//cbindgen:cbindgen_toolchain",
        "@rules_rust//rust:toolchain",
    ],
)
