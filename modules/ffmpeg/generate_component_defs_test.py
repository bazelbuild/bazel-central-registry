"""Tests for FFmpeg component extraction and config header generation."""

import ast
import tempfile
import unittest
from pathlib import Path

from generate_component_defs import (
    DECLARATIONS,
    SYNTHETIC_COMPONENTS,
    component_declarations,
    configure_dependencies,
    format_assignment,
    generate_definitions,
    literal_assignments,
    policy_definitions,
)
from generate_config_defs import (
    generate_avconfig_h,
    generate_config_h_in,
    generate_ffversion_h,
    resolve_list,
)


class ComponentFormattingTest(unittest.TestCase):
    def setUp(self):
        self.policy = (Path(__file__).parent / "7.1.1.bcr.beta.7/overlay/component_defs.bzl").read_text(
            encoding="utf-8",
        )

    def test_generated_assignments_preserve_previous_layout(self):
        names = {
            "COMPONENT_TYPES",
            "COMPONENT_REGISTRY",
            "CONFIG_EXTRA_REGISTRY",
            "ALWAYS_AVAILABLE_LIBS",
            "PROFILE_MINIMAL",
            "FILTER_SYMBOL_MAP",
        }
        for node in ast.parse(self.policy).body:
            if not isinstance(node, ast.Assign) or not isinstance(node.targets[0], ast.Name):
                continue
            name = node.targets[0].id
            if name in names:
                with self.subTest(name=name):
                    self.assertEqual(
                        format_assignment(name, ast.literal_eval(node.value)),
                        ast.get_source_segment(self.policy, node),
                    )

    def test_config_list_has_one_entry_per_line(self):
        self.assertEqual(
            format_assignment("CONFIG_LIST", ["avcodec", "libjxl"]),
            'CONFIG_LIST = [\n    "avcodec",\n    "libjxl",\n]',
        )

    def test_profile_everything_has_one_entry_per_line(self):
        self.assertEqual(
            format_assignment("PROFILE_EVERYTHING", ["aac_decoder", "libjxl_decoder"]),
            'PROFILE_EVERYTHING = [\n    "aac_decoder",\n    "libjxl_decoder",\n]',
        )

    def test_unchanged_policy_preserves_comments(self):
        values = literal_assignments(self.policy)
        expected = self.policy[
            self.policy.index("# ---------------------------------------------------------------------------") :
        ]
        self.assertEqual(
            policy_definitions(self.policy, set(values["COMPONENT_REGISTRY"])),
            expected.rstrip(),
        )


class ComponentDefinitionsTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.source = Path(self.directory.name)
        declarations = {}
        for kind, (filename, c_type, suffix) in DECLARATIONS.items():
            if kind == "parser":
                c_type = "FFCodecParser"
            elif kind == "hwaccel":
                c_type = "struct FFHWAccel"
            declarations.setdefault(filename, []).append(f"extern const {c_type}  ff_sample_{suffix};")
        declarations["libavfilter/allfilters.c"] = [
            "extern const FFFilter ff_vf_scale;",
            "extern const FFFilter ff_af_anull;",
            # configure excludes buffer filters by their doubled space.
            "extern  const FFFilter ff_vsrc_buffer;",
        ]
        for filename, lines in declarations.items():
            path = self.source / filename
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("\n".join(lines), encoding="utf-8")
        (self.source / "configure").write_text(
            'CONFIG_EXTRA="cbs cbs_av1"\n'
            'CONFIG_LIST="network pixelutils avutil"\n'
            'sample_decoder_select="cbs_av1"\n'
            'cbs_av1_select="cbs"\n'
            'scale_filter_deps="swscale"\n',
            encoding="utf-8",
        )

    def test_declaration_types_and_device_names(self):
        types, symbols = component_declarations(self.source)
        self.assertEqual(types["parser"], ["sample_parser"])
        self.assertEqual(types["hwaccel"], ["sample_hwaccel"])
        self.assertEqual(types["indev"], ["sample_indev"])
        self.assertEqual(types["outdev"], ["sample_outdev"])
        self.assertEqual(symbols, {"anull_filter": "af_anull", "scale_filter": "vf_scale"})
        self.assertNotIn("buffer_filter", types["filter"])

    def test_dependency_assignments(self):
        actual = configure_dependencies(
            'decoder_select="cbs_av1\n    itut_t35"\n'
            'decoder_deps_any="aom dav1d"\n'
            'decoder_suggest="zlib"\n'
            'decoder_conflict="other_decoder"\n'
        )
        self.assertEqual(
            actual["decoder"],
            {
                "select": ["cbs_av1", "itut_t35"],
                "deps_any": ["aom", "dav1d"],
                "suggest": ["zlib"],
                "conflict": ["other_decoder"],
            },
        )

    def test_rejects_unhandled_shell_expansion(self):
        with self.assertRaises(ValueError):
            configure_dependencies('decoder_select="$OTHER_SELECT"\n')

    def test_generation_preserves_policy_and_synthetic_settings(self):
        policy = (Path(__file__).parent / "7.1.1.bcr.beta.7/overlay/component_defs.bzl").read_text(
            encoding="utf-8",
        )
        first = generate_definitions(self.source, policy, "7.1.1.bcr.beta.7")
        self.assertEqual(first, generate_definitions(self.source, policy, "7.1.1.bcr.beta.7"))
        values = literal_assignments(first)
        self.assertEqual(values["ALWAYS_AVAILABLE_LIBS"], ["bzlib", "lzma", "threads", "zlib"])
        self.assertEqual(values["PROFILE_MINIMAL"], ["anull_filter"])
        self.assertEqual(values["MACOS_COMPONENTS"], [])
        self.assertEqual(values["LINUX_COMPONENTS"], [])
        self.assertEqual(
            values["COMPONENT_REGISTRY"]["sample_decoder"],
            {
                "select": ["cbs_av1"],
                "type": "decoder",
            },
        )
        self.assertEqual(values["CONFIG_EXTRA_REGISTRY"]["cbs_av1"], {"select": ["cbs"]})
        self.assertTrue(set(SYNTHETIC_COMPONENTS) <= values["CONFIG_EXTRA_REGISTRY"].keys())
        self.assertNotIn("exif", values["CONFIG_EXTRA_REGISTRY"])
        self.assertIn("def _compute_select_closure():", first)


class ConfigHeadersTest(unittest.TestCase):
    def test_suffix_expansion(self):
        variables = {
            "ARCH_EXT_LIST": "neon clmul",
            "HAVE_LIST": "$ARCH_EXT_LIST $(add_suffix _external $ARCH_EXT_LIST)",
        }
        self.assertEqual(
            resolve_list("HAVE_LIST", variables),
            [
                "neon",
                "clmul",
                "neon_external",
                "clmul_external",
            ],
        )

    def test_public_config_uses_target_checks(self):
        header = "\n".join(generate_avconfig_h(["bigendian", "fast_unaligned"]))
        self.assertIn("#undef AV_HAVE_BIGENDIAN", header)
        self.assertIn("#undef AV_HAVE_FAST_UNALIGNED", header)
        self.assertNotIn("#define AV_HAVE_", header)

    def test_version_uses_package_info(self):
        header = "\n".join(generate_ffversion_h())
        self.assertIn("#undef PACKAGE_VERSION", header)
        self.assertIn("#define FFMPEG_VERSION PACKAGE_VERSION", header)

    def test_config_extra_is_not_overridden(self):
        derived = [
            "dwt",
            "error_resilience",
            "gplv3",
            "libcodec2",
            "libdav1d",
            "libgsm",
            "libjxl",
            "libjxl_threads",
            "libmp3lame",
            "libopenjpeg",
            "librav1e",
            "libshine",
            "libspeex",
            "libtwolame",
            "libvorbis",
            "libvorbisenc",
            "libxvid",
            "lsp",
            "network",
            "pixelutils",
            "version3",
        ]
        header = "\n".join(
            generate_config_h_in(
                ["aarch64"],
                ["sve", "sme"],
                derived + ["resource_compression", "unstable"],
            )
        )
        for name in derived:
            self.assertNotIn(f"#define CONFIG_{name.upper()}", header)
        self.assertIn('#include "config_extra.h"', header)
        self.assertNotIn("#define FFMPEG_LICENSE", header)
        self.assertIn("#define CONFIG_RESOURCE_COMPRESSION 0", header)
        self.assertIn("#define CONFIG_UNSTABLE 0", header)
        self.assertIn("#define HAVE_SVE 0", header)
        self.assertIn("#define HAVE_SME 0", header)
        self.assertIn("#define OS_NAME @OS_NAME@", header)


if __name__ == "__main__":
    unittest.main()
