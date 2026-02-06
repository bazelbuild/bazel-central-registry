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

load("@rules_rust//rust:defs.bzl", "rust_common")

def _record_rust_impl(ctx):
    toolchain = ctx.toolchains["@rules_rust//rust:toolchain_type"]
    rustc_exec = toolchain.rustc
    
    # Declare output
    output_log = ctx.actions.declare_file(ctx.attr.outfile)

    # Collect dependencies
    direct_dep_crates = {}
    transitive_outputs = []
    search_paths = {}

    for dep in ctx.attr.deps:
        # Direct dependency crate info
        if rust_common.crate_info in dep:
            crate_info = dep[rust_common.crate_info]
            if crate_info.output:
                name = crate_info.name.replace("-", "_")
                direct_dep_crates[name] = crate_info.output
        
        # Transitive dependencies for search paths and inputs
        if rust_common.dep_info in dep:
            dep_info = dep[rust_common.dep_info]
            for crate_info in dep_info.transitive_crates.to_list():
                if crate_info.output:
                    transitive_outputs.append(crate_info.output)
                    search_paths[crate_info.output.dirname] = True


    # Prepare inputs and args
    srcs = ctx.files.srcs
    
    # Construct the base command
    cmd_parts = [
        "{rustc} {src}".format(rustc=rustc_exec.path, src=srcs[0].path),
        "--crate-type rlib",
        "--crate-name {name}".format(name=ctx.label.name.replace("-", "_")),
        "-o lib{name}.rlib".format(name=ctx.label.name.replace("-", "_")),
        "--edition {edition}".format(edition=ctx.attr.edition),        
    ]

    # Prepare features
    for feat in ctx.attr.crate_features:
        cmd_parts.append("--cfg 'feature=\"{}\"'".format(feat))

    # Add direct externs
    for name, v in direct_dep_crates.items():
        cmd_parts.append("--extern {name}={output}".format(name=name, output=v.path))

    # Add search paths for transitive dependencies
    for path in sorted(search_paths.keys()):
        cmd_parts.append("-Ldependency={}".format(path))

    # Assemble and run the command
    command = "({cmd}) > {log} 2>&1 || true".format(
        cmd=" ".join(cmd_parts),
        log=output_log.path
    )
    
    ctx.actions.run_shell(
        inputs = depset(srcs + transitive_outputs + list(direct_dep_crates.values()), transitive = [toolchain.all_files]),
        outputs = [output_log],
        tools = [rustc_exec],
        command = command,
        env = toolchain.env,
        mnemonic = "RustCompileWithLog",
    )

    # Return just the output_log/rlib
    return [
        DefaultInfo(files = depset([output_log])),
    ]

rust_library_with_log = rule(
    implementation = _record_rust_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
        "deps": attr.label_list(providers = [rust_common.crate_info]),
        "crate_features": attr.string_list(),
        "edition": attr.string(default = "2021"),
        "outfile": attr.string(mandatory = True),
    },
    toolchains = ["@rules_rust//rust:toolchain_type"],
    provides = [DefaultInfo],
)