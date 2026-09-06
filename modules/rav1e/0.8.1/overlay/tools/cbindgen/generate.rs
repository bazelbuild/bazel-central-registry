use std::{env, error::Error, fs, path::Path};

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<_> = env::args_os().collect();
    let [_, manifest_path, config_path, rav1e_source, v_frame_source, header_path, metadata_env_path] =
        args.as_slice()
    else {
        return Err(
            "expected Cargo.toml, cbindgen.toml, both lib.rs files, header, and env output".into(),
        );
    };

    let manifest: toml::Value = fs::read_to_string(manifest_path)?.parse()?;
    let package = &manifest["package"];
    let version = package["version"]
        .as_str()
        .ok_or("missing package version")?;
    let version: Vec<u64> = version
        .split(['-', '+'])
        .next()
        .unwrap()
        .split('.')
        .map(str::parse)
        .collect::<Result<_, _>>()?;
    let [major, minor, patch] = version.as_slice() else {
        return Err("expected a three-part package version".into());
    };

    let mut config = cbindgen::Config::from_file(config_path)?;
    let warning = config.autogen_warning.take().unwrap_or_default();
    config.autogen_warning = Some(format!(
        "{warning}\n#define RAV1E_MAJOR {major}\n#define RAV1E_MINOR {minor}\n#define RAV1E_PATCH {patch}\n"
    ));
    fs::create_dir_all(
        Path::new(header_path)
            .parent()
            .ok_or("missing header directory")?,
    )?;
    cbindgen::Builder::new()
        .with_config(config)
        .with_src(rav1e_source)
        .with_src(v_frame_source)
        .generate()?
        .write_to_file(header_path);

    let authors = package["authors"]
        .as_array()
        .ok_or("missing package authors")?
        .iter()
        .map(|author| author.as_str().ok_or("invalid package author"))
        .collect::<Result<Vec<_>, _>>()?
        .join(":");
    let mut metadata_env = format!("CARGO_PKG_AUTHORS={authors}\n");
    for field in ["description", "homepage", "license", "repository"] {
        let value = package
            .get(field)
            .and_then(toml::Value::as_str)
            .unwrap_or("");
        metadata_env.push_str(&format!("CARGO_PKG_{}={value}\n", field.to_uppercase()));
    }
    fs::write(metadata_env_path, metadata_env)?;
    Ok(())
}
