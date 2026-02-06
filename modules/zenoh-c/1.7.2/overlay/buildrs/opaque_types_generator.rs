use std::{collections::HashMap, path::PathBuf};

use regex::Regex;

use super::common_helpers::{features, split_type_name};
use crate::{get_build_rs_path, get_out_rs_path};

pub fn generate_opaque_types() {
    let type_to_inner_field_name = HashMap::from([("z_id_t", "pub id")]);
    let current_folder = get_out_rs_path();
    let (command, path_in) = produce_opaque_types_data();
    let path_out = current_folder.join("./opaque_types.rs");

    let data_in = std::fs::read_to_string(path_in)
        .unwrap()
        // The first error may only be preceded by a `\r`,
        // so this ensures it will be included in `total_error_count`
        .replace('\r', "\n");

    // Check for cargo-level errors (dependency resolution, manifest parsing, etc.)
    if data_in.contains("error: failed to") || data_in.contains("Caused by:") {
        panic!(
            "Failed to generate opaque types due to cargo error:\n\nCommand executed:\n\n{command}\n\nCargo output:\n\n{data_in}"
        );
    }

    let mut data_out = String::new();
    let mut docs = get_opaque_type_docs();

    // Count the total number of errors in the input data
    let total_error_count = data_in
        .lines()
        .filter(|line| line.starts_with("error[E"))
        .count();

    // Scan for type size and layout information which is generated as compilation errors
    let mut good_error_count = 0;
    let re = Regex::new(r"type: (\w+), align: (\d+), size: (\d+)").unwrap();
    for (_, [type_name, align, size]) in re.captures_iter(&data_in).map(|c| c.extract()) {
        good_error_count += 1;
        let inner_field_name = type_to_inner_field_name.get(type_name).unwrap_or(&"_0");
        let (prefix, category, semantic, postfix) = split_type_name(type_name);
        let mut s = String::new();
        if category != Some("owned") {
            s += "#[derive(Copy, Clone)]\n";
        };
        s += format!(
            "#[repr(C, align({align}))]
#[rustfmt::skip]
pub struct {type_name} {{
    {inner_field_name}: [u8; {size}],
}}
"
        )
        .as_str();
        if category == Some("owned") {
            let moved_type_name = format!("{}_{}_{}_{}", prefix, "moved", semantic, postfix);
            s += format!(
                "#[repr(C)]
#[rustfmt::skip]
pub struct {moved_type_name} {{
    _this: {type_name},
}}

#[rustfmt::skip]
impl crate::transmute::TakeCType for {moved_type_name} {{
    type CType = {type_name};
    fn take_c_type(&mut self) -> Self::CType {{
        use crate::transmute::Gravestone;
        std::mem::replace(&mut self._this, {type_name}::gravestone())
    }}
}}

#[rustfmt::skip]
impl Drop for {type_name} {{
    fn drop(&mut self) {{
        use crate::transmute::{{RustTypeRef, Gravestone, IntoRustType}};
        let _ = std::mem::replace(self.as_rust_type_mut(), {type_name}::gravestone().into_rust_type());
    }}
}}
"
            )
            .as_str();
        }

        let doc = docs
            .remove(type_name)
            .unwrap_or_else(|| panic!("Failed to extract docs for opaque type: {type_name}"));
        for d in doc {
            data_out += &d;
            data_out += "\r\n";
        }
        data_out += &s;
    }

    if good_error_count != total_error_count {
        panic!(
            "Failed to generate opaque types: there are {} errors in the input data, but only {} of them were processed as information about opaque types\n\nCommand executed:\n\n{}\n\nCompiler output:\n\n{}",
            total_error_count,
            good_error_count,
            command,
            data_in
        );
    }

    std::fs::write(path_out, data_out).unwrap();
}

fn produce_opaque_types_data() -> (String, PathBuf) {
    let target = std::env::var("TARGET").unwrap();
    let linker = std::env::var("RUSTC_LINKER").unwrap_or_default();
    let manifest_path = get_build_rs_path().join("./build-resources/opaque-types/Cargo.toml");
    let output_file_path = get_out_rs_path().join("./build_resources_opaque_types.txt");
    let out_file = std::fs::File::create(output_file_path.clone()).unwrap();
    let stdio = std::process::Stdio::from(out_file);

    let mut linker_args = Vec::<String>::new();
    if !linker.is_empty() {
        linker_args.push("--config".to_string());
        linker_args.push(format!("target.{target}.linker=\"{linker}\""));
    }
    #[allow(unused_mut)]
    let mut feature_args: Vec<&str> = vec!["-F", "panic"];
    for feature in features().iter().filter(|f| !f.is_empty()) {
        feature_args.push("-F");
        feature_args.push(feature);
    }

    // Prefer toolchain-provided cargo (e.g. rules_rust) when available.
    let cargo = std::env::var_os("CARGO").unwrap_or_else(|| "cargo".into());
    let mut command = std::process::Command::new(cargo);
    command
        .arg("build")
        .args(feature_args)
        .args(linker_args)
        .arg("--target")
        .arg(target)
        .arg("--manifest-path")
        .arg(manifest_path)
        .arg("--target-dir")
        .arg(match std::env::var("OPAQUE_TYPES_BUILD_DIR") {
            Ok(opaque_types_build_dir) => {
                println!(
                    "cargo:warning=OPAQUE_TYPES_BUILD_DIR = {}",
                    opaque_types_build_dir
                );
                opaque_types_build_dir.into()
            }
            Err(_) => get_out_rs_path().join("./build_resources/opaque_types"),
        });

    let command_str = format!("{:?}", command);
    let _ = command.stderr(stdio).output().unwrap();
    (command_str, output_file_path)
}

fn get_opaque_type_docs() -> HashMap<String, Vec<String>> {
    let current_folder = get_build_rs_path();
    let path_in = current_folder.join("./build-resources/opaque-types/src/lib.rs");
    let re = Regex::new(r"(?m)^get_opaque_type_data!\(\s*(.*)\s*,\s*(\w+)\s*(,)?\s*\);").unwrap();
    let mut comments = Vec::new();
    let mut opaque_lines = Vec::new();
    let mut res = HashMap::new();
    for line in std::fs::read_to_string(&path_in)
        .unwrap_or_else(|_| panic!("failed to read file {}", path_in.display()))
        .lines()
    {
        if line.starts_with("///") {
            comments.push(line.to_string());
            continue;
        }
        if line.starts_with("get_opaque_type_data!(") || !opaque_lines.is_empty() {
            opaque_lines.push(line);
        }
        if !opaque_lines.is_empty() && line.ends_with(");") {
            let joined_lines = std::mem::take(&mut opaque_lines).join("");
            let capture = re.captures(&joined_lines).expect("invalid opaque type");
            res.insert(capture[2].to_string(), std::mem::take(&mut comments));
        }
    }
    res
}
