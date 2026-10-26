"""Regression tests for FFmpeg's generated external-library configuration."""

import ast
import re
import unittest
from pathlib import Path

from generate_component_defs import literal_assignments


class ComponentConfigTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        overlay = Path(__file__).parent / "9.0.1.beta.bcr/overlay"
        definitions = (overlay / "component_defs.bzl").read_text(encoding="utf-8")
        configuration = (overlay / "component_config.bzl").read_text(encoding="utf-8")
        cls.namespace = literal_assignments(definitions) | literal_assignments(configuration)
        # These header-formatting functions use the Python-compatible subset
        # of Starlark. Load only the functions, without evaluating Bazel rules.
        functions = [
            node
            for node in ast.parse(configuration).body
            if isinstance(node, ast.FunctionDef) and node.name in {"_component_type_enabled", "_gen_config_extra"}
        ]
        exec(compile(ast.Module(body=functions, type_ignores=[]), str(overlay), "exec"), cls.namespace)

    def config(self, state):
        header = self.namespace["_gen_config_extra"](state)
        definitions = re.findall(r"^#define (\w+) (.*)$", header, re.MULTILINE)
        self.assertEqual(len(definitions), len(dict(definitions)), "configuration macros must not be redefined")
        return dict(definitions)

    def test_external_libraries_default_to_disabled(self):
        config = self.config({})
        for library in self.namespace["EXTERNAL_CODEC_LIBRARIES"]:
            self.assertEqual(config["CONFIG_" + library.upper()], "0")
        self.assertEqual(config["CONFIG_LIBJXL_THREADS"], "0")
        self.assertEqual(config["CONFIG_LIBVORBISENC"], "0")
        self.assertEqual(config["CONFIG_GPLV3"], "0")
        self.assertEqual(config["CONFIG_VERSION3"], "0")
        self.assertEqual(config["FFMPEG_LICENSE"], '"LGPL version 2.1 or later"')

    def test_each_component_enables_only_its_library(self):
        libraries = self.namespace["EXTERNAL_CODEC_LIBRARIES"]
        for library, components in libraries.items():
            for component in components:
                with self.subTest(component=component):
                    state = {component: True}
                    config = self.config(state)
                    for name in libraries:
                        self.assertEqual(config["CONFIG_" + name.upper()], "1" if name == library else "0")
                    self.assertEqual(config["CONFIG_LIBJXL_THREADS"], "1" if library == "libjxl" else "0")
                    self.assertEqual(config["CONFIG_LIBVORBISENC"], "1" if component == "libvorbis_encoder" else "0")
                    self.assertEqual(state, {component: True})

    def test_external_gpl_codecs_report_gplv3_without_enabling_internal_gpl_sources(self):
        for component in self.namespace["GPL_EXTERNAL_CODECS"] + ["gplv3"]:
            with self.subTest(component=component):
                config = self.config({component: True})
                self.assertEqual(config["CONFIG_GPLV3"], "1")
                self.assertEqual(config["CONFIG_VERSION3"], "1")
                self.assertEqual(config["FFMPEG_LICENSE"], '"GPL version 3 or later"')
                self.assertNotIn("CONFIG_GPL", config)

    def test_explicit_lgplv3_is_reported_consistently(self):
        config = self.config({"lgplv3": True})
        self.assertEqual(config["CONFIG_GPLV3"], "0")
        self.assertEqual(config["CONFIG_LGPLV3"], "1")
        self.assertEqual(config["CONFIG_VERSION3"], "1")
        self.assertEqual(config["FFMPEG_LICENSE"], '"LGPL version 3 or later"')


if __name__ == "__main__":
    unittest.main()
