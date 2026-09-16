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

load("@rules_rust//rust:rust_common.bzl", "CrateInfo")

# Supported rule kinds for the cargo manifest aspect
_SUPPORTED_LIB_KINDS = ["rust_library", "rust_shared_library", "rust_static_library"]
_SUPPORTED_BIN_KINDS = ["rust_binary"]
_SUPPORTED_KINDS = _SUPPORTED_LIB_KINDS + _SUPPORTED_BIN_KINDS

CargoManifestInfo = provider(
    doc = "A provider containing information about a Crate's cargo metadata.",
    fields = {
        "toml": "The current crate's Cargo.toml file.",
        "deps": "The Cargo.toml files the current crate depends on.",
    },
)

def _path_parts(path):
    """Takes a path and returns a list of its parts with all "." elements removed.

    The main use case of this function is if one of the inputs to relativize()
    is a relative path, such as "./foo".

    Args:
      path (str): A string representing a unix path

    Returns:
      list: A list containing the path parts with all "." elements removed.
    """
    path_parts = path.split("/")
    return [part for part in path_parts if part != "."]

def _relativize(path, start):
    """Returns the relative path from start to path.

    Args:
        path (str): The path to relativize.
        start (str): The ancestor path against which to relativize.

    Returns:
        str: The portion of `path` that is relative to `start`.
    """
    src_parts = _path_parts(start)
    dest_parts = _path_parts(path)
    n = 0
    for src_part, dest_part in zip(src_parts, dest_parts):
        if src_part != dest_part:
            break
        n += 1

    relative_path = ""
    for _ in range(n, len(src_parts)):
        relative_path += "../"
    relative_path += "/".join(dest_parts[n:])

    return relative_path

def _output_dir(ctx):
    """Returns the output directory the aspect should write into.

    Args:
        ctx (ctx): The current aspect's context object

    Returns:
        string: The output directory name for the current aspect
    """
    return "cargo_manifest.aspect/{}".format(ctx.rule.attr.name)

def _is_external_crate(target):
    """Returns whether or not the target is an external target.

    eg: `@bazel_skylib//:lib` is an external target where as `@io_bazel_rules_rust//:lib` or `//:lib` are not.

    Args:
        target (Target): The target the aspect is being applied to.

    Returns:
        bool: True if the target is an external target
    """
    return target.label.workspace_root.startswith("external")

def _clone_external_crate_sources(ctx, target):
    """Creates copies of the source files for external crates.

    This is done to ensure manifests generated for external targets can always refer to it's source code via
    some predictable path.

    Args:
        ctx (ctx): The current aspect's context object
        target (Target): The target the aspect is being applied to.

    Returns:
        tuple: A tuple of the following items:
            - (list): A list of `File`s created by this macro
            - (File): The generated file matching `target`'s crate root.
    """
    if not _is_external_crate(target):
        fail("{} is not an external target".format(target.label))

    crate_info = target[CrateInfo]
    outputs = []
    copy_commands = []
    root = None
    for src in crate_info.srcs.to_list():
        external_crate_short_path = src.short_path[len("../"):]
        output = ctx.actions.declare_file("{}/{}".format(_output_dir(ctx), external_crate_short_path))
        outputs.append(output)
        copy_commands.append("mkdir -p {} ; cp {} {}".format(
            output.dirname,
            src.path,
            output.path,
        ))
        if src.path == crate_info.root.path:
            root = output
    
    command = "\n".join(copy_commands)
    ctx.actions.run_shell(
        outputs = outputs,
        inputs = crate_info.srcs,
        command = command,
    )

    return outputs, root

def _find_crate_root_from_srcs(srcs):
    """Find the crate root file from a list of source files.
    
    Looks for lib.rs or main.rs as conventional entry points.
    
    Args:
        srcs: List of source files
        
    Returns:
        File: The crate root file, or None if not found
    """
    for src in srcs:
        if src.basename == "lib.rs" or src.basename == "main.rs":
            return src
    # Fallback to first .rs file if no conventional root found
    for src in srcs:
        if src.path.endswith(".rs"):
            return src
    return None

def _clone_external_sources(ctx, target, src_files):
    """Creates copies of the source files for external crates without CrateInfo.

    This is done to ensure manifests generated for external targets can always refer to source code via
    some predictable path within the output directory.

    Args:
        ctx (ctx): The current aspect's context object
        target (Target): The target the aspect is being applied to.
        src_files (list): List of source files to clone

    Returns:
        tuple: A tuple of the following items:
            - (list): A list of `File`s created by this macro
            - (File): The generated file matching the crate root.
    """
    outputs = []
    copy_commands = []
    root = None
    original_root = _find_crate_root_from_srcs(src_files)
    
    for src in src_files:
        # Get the path relative to the external repo
        if src.short_path.startswith("../"):
            external_crate_short_path = src.short_path[len("../"):]
        else:
            external_crate_short_path = src.short_path
            
        output = ctx.actions.declare_file("{}/{}".format(_output_dir(ctx), external_crate_short_path))
        outputs.append(output)
        copy_commands.append("mkdir -p {} ; cp {} {}".format(
            output.dirname,
            src.path,
            output.path,
        ))
        if original_root and src.path == original_root.path:
            root = output
    
    if outputs:
        command = "\n".join(copy_commands)
        ctx.actions.run_shell(
            outputs = outputs,
            inputs = src_files,
            command = command,
        )
    
    return outputs, root

_CARGO_MANIFEST_TEMPLATE = """\
# Generated by `cargo_manifest_aspect` from `{target_label}` in `{build_file_path}`
[package]
name = "{name}"
version = "{version}"
edition = "{edition}"

{crate_type}
name = "{name}"
path = "{path}"

[dependencies]
{dependencies}
"""

def _cargo_manifest_aspect_impl(target, ctx):
    """Creates a separate Cargo.toml for each instance of a rust rule.

    Relies on a separate step to create the workspace Cargo.toml that makes use of them.

    Args:
        target (Target): The target the aspect is being applied to.
        ctx (ctx): The current aspect's context object

    Returns:
        list: A list of providers
            - (CargoManifestInfo): Information about the current target
            - (OutputGroupInfo): A provider that indicates what output groups a rule has.
    """
    rule = ctx.rule
    
    # Check if this is a supported rule kind
    is_lib = rule.kind in _SUPPORTED_LIB_KINDS
    is_bin = rule.kind in _SUPPORTED_BIN_KINDS
    if not (is_lib or is_bin):
        return []

    manifest = ctx.actions.declare_file("{}/Cargo.toml".format(_output_dir(ctx)))
    rust_deps = [dep for dep in rule.attr.deps if CrateInfo in dep or CargoManifestInfo in dep]
    
    # Filter to only deps that have CargoManifestInfo (generated by this aspect)
    manifest_deps = [dep for dep in rust_deps if CargoManifestInfo in dep]
    
    # Check if we have CrateInfo (rust_library) or need to get info another way
    has_crate_info = CrateInfo in target

    # Handle external crates vs local crates for source file discovery
    if _is_external_crate(target) and has_crate_info:
        srcs, root_src = _clone_external_crate_sources(ctx, target)
    elif has_crate_info:
        srcs = []
        root_src = target[CrateInfo].root
    elif _is_external_crate(target):
        # For external rust_shared_library/rust_static_library without CrateInfo,
        # we need to clone source files to the output directory
        src_files = []
        for src in rule.attr.srcs:
            src_files.extend(src.files.to_list())
        srcs, root_src = _clone_external_sources(ctx, target, src_files)
        if not root_src:
            fail("Could not find crate root (lib.rs or main.rs) in srcs for {}".format(target.label))
    else:
        # For local rust_shared_library/rust_static_library, find root from srcs attribute
        srcs = []
        src_files = []
        for src in rule.attr.srcs:
            src_files.extend(src.files.to_list())
        root_src = _find_crate_root_from_srcs(src_files)
        if not root_src:
            fail("Could not find crate root (lib.rs or main.rs) in srcs for {}".format(target.label))
    
    # Get edition - from CrateInfo if available, otherwise use rule attribute or default
    if has_crate_info:
        edition = target[CrateInfo].edition
    elif hasattr(rule.attr, "edition") and rule.attr.edition:
        edition = rule.attr.edition
    else:
        edition = "2021"  # Default to Rust 2021 edition
    
    # Determine crate type for Cargo.toml
    if rule.kind == "rust_shared_library":
        crate_type_section = "[lib]\ncrate-type = [\"cdylib\"]"
    elif rule.kind == "rust_static_library":
        crate_type_section = "[lib]\ncrate-type = [\"staticlib\"]"
    elif rule.kind == "rust_library":
        crate_type_section = "[lib]"
    else:
        crate_type_section = "[[bin]]"

    ctx.actions.write(
        output = manifest,
        content = _CARGO_MANIFEST_TEMPLATE.format(
            target_label = target.label,
            build_file_path = ctx.build_file_path,
            crate_type = crate_type_section,
            name = target.label.name,
            version = rule.attr.version if hasattr(rule.attr, "version") else "0.0.0",
            edition = edition,
            path = _relativize(root_src.path, manifest.dirname),
            dependencies = "\n".join([
                "{} = {{ path = \"{}\" }}".format(
                    dep.label.name,
                    _relativize(
                        dep[CargoManifestInfo].toml.dirname, manifest.dirname
                    )
                )
                for dep in manifest_deps
            ]),
        ),
    )

    deps = [dep[OutputGroupInfo].all_files for dep in manifest_deps if OutputGroupInfo in dep]

    return [
        CargoManifestInfo(
            toml = manifest,
            deps = depset(transitive = deps),
        ),
        OutputGroupInfo(
            all_files = depset([manifest], transitive = deps + [depset(srcs)]),
        ),
    ]

cargo_manifest_aspect = aspect(
    doc = "An aspect that generates Cargo metadata (Cargo.toml files) for `rust_binary` and `rust_library` targets.",
    attr_aspects = ["deps"],
    implementation = _cargo_manifest_aspect_impl,
    toolchains = ["@rules_rust//rust:toolchain"],
)