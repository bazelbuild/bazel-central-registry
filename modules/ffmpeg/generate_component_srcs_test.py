"""Regression tests for FFmpeg's component source generator."""

import ast
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import generate_component_srcs as generator


def generated_assignments(lines):
    return {
        node.targets[0].id: ast.literal_eval(node.value)
        for node in ast.parse("\n".join(lines)).body
        if isinstance(node, ast.Assign)
    }


class ComponentSourcesTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name)
        self.flags = patch.multiple(
            generator,
            PROFILE_EVERYTHING_SET={"hevc_decoder", "vvc_decoder", "matroska_muxer", "webm_muxer"},
            CONFIG_EXTRA_SET={"dsp", "network"},
            STATIC_CONFIG_SET=set(),
        )
        self.flags.start()
        self.addCleanup(self.flags.stop)

    def write(self, name, text=""):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def process_codec(self, sub_makefiles=()):
        return generator.process_library(
            self.root,
            generator.LibInfo("avcodec", "libavcodec", list(sub_makefiles)),
        )

    def test_registry_keys_are_read_without_evaluating_starlark(self):
        path = self.write(
            "component_defs.bzl",
            'load(":unused.bzl", "unused")\n'
            'PROFILE_EVERYTHING = ["hevc_decoder"]  # "not_a_component"\n'
            'CONFIG_EXTRA_REGISTRY = {"dsp": {"select": ["other"]}}\n',
        )
        self.assertEqual(generator.load_profile_everything(path), {"hevc_decoder"})
        self.assertEqual(generator.load_registry_keys(path, "CONFIG_EXTRA_REGISTRY"), {"dsp"})

    def test_makefile_static_architecture_and_feature_selection(self):
        path = self.write(
            "Makefile",
            "OBJS = base.o \\\n"
            "       base2.o\n"
            "OBJS-$(CONFIG_HEVC_DECODER) += decoder.o \\\n"
            "                             common.o # ignored.o\n"
            "STLIBOBJS-$(CONFIG_HEVC_DECODER) += static.o\n"
            "SHLIBOBJS-$(CONFIG_HEVC_DECODER) += shared.o\n"
            "ifdef ARCH_X86_64\n"
            "X86ASM-OBJS-$(CONFIG_HEVC_DECODER) += x86/idct64.o\n"
            "else\n"
            "X86ASM-OBJS-$(CONFIG_HEVC_DECODER) += x86/idct32.o\n"
            "endif\n"
            "ifdef CONFIG_GPL\n"
            "X86ASM-OBJS-$(CONFIG_HEVC_DECODER) += x86/gpl.o\n"
            "endif\n"
            "NEON-OBJS-$(CONFIG_HEVC_DECODER) += aarch64/neon.o\n"
            "SVE-OBJS-$(CONFIG_HEVC_DECODER) += aarch64/sve.o\n"
            "SME2-OBJS-$(CONFIG_HEVC_DECODER) += aarch64/sme2.o\n"
            "OBJS-$(CONFIG_UNSTABLE) += unstable.o\n",
        )
        self.assertEqual(generator.parse_unconditional_objs(path), {"base.o", "base2.o"})
        self.assertEqual(
            generator.parse_makefile(path),
            {"hevc_decoder": ["decoder.o", "common.o", "static.o", "x86/idct64.o", "aarch64/neon.o"]},
        )

    def test_sources_shared_by_components_and_subsystems_appear_once(self):
        self.write(
            "libavcodec/Makefile",
            "OBJS = base.o\n"
            "OBJS-$(CONFIG_HEVC_DECODER) += base.o decoder.o shared.o missing.o\n"
            "OBJS-$(CONFIG_VVC_DECODER) += shared.o\n"
            "OBJS-$(CONFIG_DSP) += dsp.o shared.o\n",
        )
        for name in ["base", "decoder", "shared", "dsp"]:
            self.write("libavcodec/" + name + ".c")
        sources = self.process_codec()
        self.assertEqual(sources.components.exclusive, {"hevc_decoder": ["libavcodec/decoder.c"]})
        self.assertEqual(sources.components.shared, [])
        self.assertEqual(sources.extra.exclusive, {"dsp": ["libavcodec/dsp.c"]})
        self.assertEqual(
            sources.extra.shared,
            [(["dsp", "hevc_decoder", "vvc_decoder"], ["libavcodec/shared.c"])],
        )

    def test_static_sub_makefile_objects_keep_library_relative_names(self):
        self.write("libavcodec/Makefile", "OBJS = base.o\n")
        self.write(
            "libavcodec/opus/Makefile",
            "STLIBOBJS-$(CONFIG_MATROSKA_MUXER) += opus/frame_duration_tab.o\n"
            "STLIBOBJS-$(CONFIG_WEBM_MUXER) += opus/frame_duration_tab.o\n",
        )
        self.write("libavcodec/opus/frame_duration_tab.c")
        sources = self.process_codec(["opus"])
        self.assertEqual(
            sources.components.shared,
            [(["matroska_muxer", "webm_muxer"], ["libavcodec/opus/frame_duration_tab.c"])],
        )

    def test_fixed_configs_select_static_sources_without_conditional_duplicates(self):
        template = self.write(
            "config.h.in",
            "#define CONFIG_AVFORMAT 1\n#define CONFIG_SMALL 0\n#define CONFIG_OTHER_VALUE 11\n#undef CONFIG_DYNAMIC\n",
        )
        generator.STATIC_CONFIG_SET = generator.load_static_configs(template)
        self.assertEqual(generator.STATIC_CONFIG_SET, {"avformat"})
        generator.PROFILE_EVERYTHING_SET = {"lcevc_parser"}
        generator.CONFIG_EXTRA_SET = {"h264parse", "mpegvideo"}
        self.write(
            "libavcodec/Makefile",
            "STLIBOBJS-$(CONFIG_AVFORMAT) += h2645_parse.o lcevctab.o to_upper4.o\n"
            "OBJS-$(CONFIG_H264PARSE) += h2645_parse.o\n"
            "OBJS-$(CONFIG_LCEVC_PARSER) += lcevc_parser.o lcevctab.o\n"
            "OBJS-$(CONFIG_MPEGVIDEO) += mpegvideo.o to_upper4.o\n"
            "OBJS-$(CONFIG_SMALL) += small.o\n",
        )
        for name in ["h2645_parse", "lcevctab", "to_upper4", "lcevc_parser", "mpegvideo", "small"]:
            self.write("libavcodec/" + name + ".c")
        sources = self.process_codec()
        self.assertEqual(
            sources.unconditional,
            ["libavcodec/h2645_parse.c", "libavcodec/lcevctab.c", "libavcodec/to_upper4.c"],
        )
        self.assertEqual(sources.components, ({"lcevc_parser": ["libavcodec/lcevc_parser.c"]}, []))
        self.assertEqual(sources.extra, ({"mpegvideo": ["libavcodec/mpegvideo.c"]}, []))
        output = []
        generator._emit_library_to(
            generator.LibInfo("avcodec", "libavcodec", []),
            self.root,
            {},
            [0],
            lambda line="": output.append(line),
        )
        namespace = generated_assignments(output)
        self.assertEqual(namespace["AVCODEC_EXTRA_SRCS"], sources.unconditional)

    def test_neon_intrinsics_are_merged_into_aarch64_sources_only(self):
        generator.CONFIG_EXTRA_SET = {"mpegvideo"}
        self.write("libavcodec/Makefile", "")
        for directory in ["aarch64", "neon"]:
            self.write(
                "libavcodec/" + directory + "/Makefile",
                "OBJS-$(CONFIG_MPEGVIDEO) += " + directory + "/mpegvideo.o\n",
            )
            self.write("libavcodec/" + directory + "/mpegvideo.c")
        sources = self.process_codec()
        self.assertEqual(
            sources.aarch64,
            (
                {"mpegvideo": ["libavcodec/aarch64/mpegvideo.c", "libavcodec/neon/mpegvideo.c"]},
                [],
            ),
        )
        self.assertEqual(sources.unconditional, [])
        self.assertEqual(sources.components, ({}, []))
        self.assertEqual(sources.extra, ({}, []))
        self.assertEqual(sources.x86, ({}, []))
        self.assertEqual(sources.x86_asm, ({}, []))

    def test_nested_architecture_makefiles_separate_nasm_and_c(self):
        self.write("libavcodec/Makefile", "")
        for codec in ["hevc", "vvc"]:
            self.write(
                "libavcodec/x86/" + codec + "/Makefile",
                "X86ASM-OBJS-$(CONFIG_" + codec.upper() + "_DECODER) += "
                "x86/" + codec + "/dsp_init.o x86/h26x/inter.o\n",
            )
            self.write("libavcodec/x86/" + codec + "/dsp_init.c")
        self.write("libavcodec/x86/h26x/inter.asm")
        self.write("libavcodec/x86/h26x/include_only.asm")
        self.write(
            "libavcodec/aarch64/vvc/Makefile",
            "OBJS-$(CONFIG_VVC_DECODER) += aarch64/vvc/dsp_init.o\n"
            "NEON-OBJS-$(CONFIG_VVC_DECODER) += aarch64/vvc/inter.o\n"
            "SME2-OBJS-$(CONFIG_VVC_DECODER) += aarch64/vvc/inter_sme2.o\n",
        )
        self.write("libavcodec/aarch64/vvc/dsp_init.c")
        self.write("libavcodec/aarch64/vvc/inter.S")
        self.write("libavcodec/aarch64/vvc/inter_sme2.S")
        sources = self.process_codec()
        self.assertEqual(
            sources.x86.exclusive,
            {
                "hevc_decoder": ["libavcodec/x86/hevc/dsp_init.c"],
                "vvc_decoder": ["libavcodec/x86/vvc/dsp_init.c"],
            },
        )
        self.assertEqual(
            sources.x86_asm.shared,
            [(["hevc_decoder", "vvc_decoder"], ["libavcodec/x86/h26x/inter.asm"])],
        )
        self.assertEqual(
            sources.aarch64.exclusive,
            {"vvc_decoder": ["libavcodec/aarch64/vvc/dsp_init.c", "libavcodec/aarch64/vvc/inter.S"]},
        )

    def test_tls_backend_and_network_sources_remain_selected_by_build(self):
        generator.PROFILE_EVERYTHING_SET = {"dtls_protocol", "tls_protocol"}
        self.write(
            "libavformat/Makefile",
            "OBJS-$(CONFIG_NETWORK) += network.o\n"
            "OBJS-$(CONFIG_TLS_PROTOCOL) += tls.o tls_openssl.o\n"
            "OBJS-$(CONFIG_DTLS_PROTOCOL) += tls.o tls_mbedtls.o\n",
        )
        for name in ["network", "tls", "tls_openssl", "tls_mbedtls"]:
            self.write("libavformat/" + name + ".c")
        sources = generator.process_library(self.root, generator.LibInfo("avformat", "libavformat", []))
        self.assertEqual(sources.extra, ({}, []))
        self.assertEqual(sources.components.exclusive, {})
        self.assertEqual(
            sources.components.shared,
            [(["dtls_protocol", "tls_protocol"], ["libavformat/tls.c"])],
        )

    def test_emitted_architecture_and_extra_exports_register_shared_groups(self):
        self.write(
            "libavcodec/Makefile",
            "OBJS-$(CONFIG_DSP) += shared.o\nOBJS-$(CONFIG_HEVC_DECODER) += shared.o\n",
        )
        self.write("libavcodec/shared.c")
        groups = {}
        output = []
        generator._emit_library_to(
            generator.LibInfo("avcodec", "libavcodec", []),
            self.root,
            groups,
            [0],
            lambda line="": output.append(line),
        )
        namespace = generated_assignments(output)
        for prefix in ["AVCODEC", "AVCODEC_EXTRA", "AVCODEC_AARCH64", "AVCODEC_X86", "AVCODEC_X86_ASM"]:
            self.assertIn(prefix + "_EXCLUSIVE_SRCS", namespace)
            self.assertIn(prefix + "_SHARED_SRCS", namespace)
        for name, value in namespace.items():
            if name.endswith("_SHARED_SRCS"):
                for components, _ in value:
                    self.assertIn(tuple(components), groups)
        self.assertEqual(namespace["AVCODEC_EXTRA_SRCS"], [])
        self.assertEqual(namespace["AVCODEC_AARCH64_COMPONENT_SRCS"], [])
        self.assertEqual(namespace["AVCODEC_X86_COMPONENT_SRCS"], [])

    def test_nasm_directory_partition_keeps_equal_basenames_separate(self):
        groups = generator.SourceGroups(
            {
                "hevc_decoder": ["libavcodec/x86/hevc/mc.asm"],
                "vvc_decoder": ["libavcodec/x86/vvc/mc.asm"],
            },
            [
                (
                    ["hevc_decoder", "vvc_decoder"],
                    ["libavcodec/x86/h26x/common.asm", "libavcodec/x86/other.asm"],
                ),
            ],
        )
        output = []
        generator._emit_asm_directories_to("AVCODEC_X86_ASM", groups, lambda line="": output.append(line))
        namespace = generated_assignments(output)
        exclusive = namespace["AVCODEC_X86_ASM_EXCLUSIVE_SRCS_BY_DIR"]
        shared = namespace["AVCODEC_X86_ASM_SHARED_SRCS_BY_DIR"]
        self.assertEqual(set(exclusive), set(shared))
        self.assertEqual(exclusive["libavcodec/x86/hevc"], {"hevc_decoder": ["libavcodec/x86/hevc/mc.asm"]})
        self.assertEqual(exclusive["libavcodec/x86/vvc"], {"vvc_decoder": ["libavcodec/x86/vvc/mc.asm"]})
        self.assertEqual(
            shared["libavcodec/x86/h26x"],
            [(("hevc_decoder", "vvc_decoder"), ["libavcodec/x86/h26x/common.asm"])],
        )
        self.assertEqual(
            shared["libavcodec/x86"],
            [(("hevc_decoder", "vvc_decoder"), ["libavcodec/x86/other.asm"])],
        )


if __name__ == "__main__":
    unittest.main()
