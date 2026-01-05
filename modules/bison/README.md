# Bison

## Generating config files

To generate `config_*` overlay files, use the following instructions:

1. Configure and build Bison on the target system (e.g. linux/macos/etc).
2. Run the `generate_bison_config_bzl.py` script.

If the Bison build was successful and all the requested arguments were passed to
`generate_bison_config_bzl.py`, there should be new `config_*.bzl` and `config_*.h`
files in the provided version.
