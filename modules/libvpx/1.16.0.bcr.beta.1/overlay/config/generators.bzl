load(":vpx_config.bzl", "vpx_config_asm", "vpx_config_header", "vpx_config_rtcd")

def emit_x86_config_generators(arch):
    vpx_config_header(
        name = "gen_{}_h".format(arch),
        arch = arch,
        out = "generated/{}/vpx_config.h".format(arch),
    )

    vpx_config_header(
        name = "gen_{}_windows_h".format(arch),
        arch = arch,
        out = "generated/{}_windows/vpx_config.h".format(arch),
        windows = True,
    )

    vpx_config_asm(
        name = "gen_{}_asm".format(arch),
        arch = arch,
        out = "generated/{}/vpx_config.asm".format(arch),
    )

    vpx_config_asm(
        name = "gen_{}_windows_asm".format(arch),
        arch = arch,
        out = "generated/{}_windows/vpx_config.asm".format(arch),
        windows = True,
    )

    vpx_config_rtcd(
        name = "gen_{}_rtcd".format(arch),
        arch = arch,
        out = "generated/{}/vpx_config.rtcd".format(arch),
    )

    vpx_config_rtcd(
        name = "gen_{}_windows_rtcd".format(arch),
        arch = arch,
        out = "generated/{}_windows/vpx_config.rtcd".format(arch),
        windows = True,
    )
