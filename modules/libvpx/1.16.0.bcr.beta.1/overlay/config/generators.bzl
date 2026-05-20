load(":vpx_config.bzl", "vpx_config_asm", "vpx_config_header", "vpx_config_rtcd")

_KIND_TO_FILENAME = {
    "asm": "vpx_config.asm",
    "h": "vpx_config.h",
    "rtcd": "vpx_config.rtcd",
}

def config_output_dir(family, variant = "default"):
    return "generated/{}/{}".format(family, variant)

def config_output_file(family, variant, kind):
    return "{}/{}".format(config_output_dir(family, variant), _KIND_TO_FILENAME[kind])

def select_config_outputs(family, kind, variants_by_condition):
    return select({
        condition: [config_output_file(family, variant, kind)]
        for condition, variant in variants_by_condition.items()
    })

def select_config_dirs(family, variants_by_condition):
    return select({
        condition: [config_output_dir(family, variant)]
        for condition, variant in variants_by_condition.items()
    })

def _emit_variant_config_targets(family, arch, variant, features = {}, windows = False, emit_asm = True):
    name_prefix = "gen_{}_{}".format(family, variant)

    vpx_config_header(
        name = "{}_h".format(name_prefix),
        arch = arch,
        out = config_output_file(family, variant, "h"),
        features = features,
        windows = windows,
    )

    if emit_asm:
        vpx_config_asm(
            name = "{}_asm".format(name_prefix),
            arch = arch,
            out = config_output_file(family, variant, "asm"),
            features = features,
            windows = windows,
        )

    vpx_config_rtcd(
        name = "{}_rtcd".format(name_prefix),
        arch = arch,
        out = config_output_file(family, variant, "rtcd"),
        features = features,
        windows = windows,
    )

def emit_config_family_targets(family, arch, variants):
    for variant in variants:
        _emit_variant_config_targets(
            family = family,
            arch = arch,
            variant = variant["name"],
            features = variant.get("features", {}),
            windows = variant.get("windows", False),
            emit_asm = variant.get("emit_asm", True),
        )
