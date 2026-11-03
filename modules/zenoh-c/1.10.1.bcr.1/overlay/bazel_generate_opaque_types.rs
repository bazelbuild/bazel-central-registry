// Copyright 2026 Open Source Robotics Foundation, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

use regex::Regex;
use std::collections::HashMap;
use std::env;
use std::path::{Path, PathBuf};
use std::process;

pub fn split_type_name(type_name: &str) -> (&str, Option<&str>, &str, &str) {
    let mut split = type_name.split('_');
    let prefix = split
        .next()
        .unwrap_or_else(|| panic!("Fist '_' not found in type name: {type_name}"));
    let cat = split
        .next()
        .unwrap_or_else(|| panic!("Second '_' not found in type name: {type_name}"));
    let category = if cat != "owned" && cat != "loaned" && cat != "moved" {
        None
    } else {
        Some(cat)
    };
    let postfix = split.next_back().expect("Type should end with '_t'");
    let prefix_cat_len = prefix.len() + 1 + category.map(|c| c.len() + 1).unwrap_or(0);
    let semantic = &type_name[prefix_cat_len..type_name.len() - postfix.len() - 1];
    (prefix, category, semantic, postfix)
}

fn get_opaque_type_docs(path_in: PathBuf) -> HashMap<String, Vec<String>> {
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

fn transform_opaque_types(path_doc: PathBuf, path_txt: PathBuf, path_out: PathBuf) {
    let type_to_inner_field_name = HashMap::from([("z_id_t", "pub id")]);
    let data_in = std::fs::read_to_string(path_txt)
        .unwrap()
        .replace('\r', "\n");

    if data_in.contains("error: failed to") || data_in.contains("Caused by:") {
        panic!("Failed to generate opaque types due to malformed input txt file");
    }

    let mut data_out = String::new();
    let mut docs = get_opaque_type_docs(path_doc);

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
            "Error: {} of {} opaque types processed. Compiler output:\n\n{}",
            good_error_count, total_error_count, data_in
        );
    }

    std::fs::write(path_out, data_out).unwrap();
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 4 {
        let path = Path::new(&args[0]);
        let filename = path.file_name().unwrap();
        eprintln!(
            "Usage: {} <doc file> <txt file> <out_file>",
            filename.to_str().unwrap()
        );
        process::exit(1);
    }
    let path_doc = PathBuf::from(&args[1]);
    let path_txt = PathBuf::from(&args[2]);
    let path_out = PathBuf::from(&args[3]);
    transform_opaque_types(path_doc, path_txt, path_out);
}