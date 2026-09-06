"""Exercise Bazel-built Pango through explicit runfiles paths, without linking it."""

import argparse
import ctypes as C
import os
from pathlib import Path
import shutil
import tempfile

from python.runfiles import runfiles


def function(lib, name, result, *args):
    fn = getattr(lib, name)
    fn.restype = result
    fn.argtypes = list(args)
    return fn


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("first", type=int, choices=range(3))
    parser.add_argument("paths", nargs=5)
    parser.add_argument("--relocate", action="store_true")
    parser.add_argument("--dictionary")
    args = parser.parse_args()
    rf = runfiles.Create()
    paths = [Path(rf.Rlocation(arg)).resolve(strict=True) for arg in args.paths]
    first = args.first
    if args.relocate:
        relocated = tempfile.TemporaryDirectory()
        paths[:3] = [Path(shutil.copy2(path, relocated.name)) for path in paths[:3]]
        assert {path.name for path in Path(relocated.name).iterdir()} == {
            "libpango-1.0.so.0",
            "libpangoft2-1.0.so.0",
            "libpangocairo-1.0.so.0",
        }
    # The default must work without a dictionary file or an inherited override.
    os.environ.pop("LIBTHAI_DICTDIR", None)
    if args.dictionary:
        dictionary = Path(rf.Rlocation(args.dictionary)).resolve(strict=True)
        os.environ["LIBTHAI_DICTDIR"] = str(dictionary.parent)
    # RTLD_NOW rejects missing symbols even for code not called by this test.
    handles = [None] * 3
    for index in [first] + [i for i in range(3) if i != first]:
        handles[index] = C.CDLL(str(paths[index]), mode=os.RTLD_NOW | os.RTLD_LOCAL)
    pango, ft2, cairo = handles
    ptr, integer, string = C.c_void_p, C.c_int, C.c_char_p
    assert function(pango, "pango_version", integer)() == 15603
    assert function(pango, "pango_version_string", string)() == b"1.56.3"

    # All three handles must resolve the same core/GObject implementation.
    for name in ["pango_font_map_get_type", "g_object_unref", "g_type_from_name"]:
        addresses = [C.cast(getattr(h, name), ptr).value for h in handles]
        assert len(set(addresses)) == 1, (name, addresses)
    assert (
        function(ft2, "pango_fc_font_map_get_type", C.c_size_t)()
        == function(cairo, "pango_fc_font_map_get_type", C.c_size_t)()
    )

    # Dictionary-backed Thai breaks: the same sentence used by libthai tests.
    thai = "สวัสดีครับ กอ.รมน. นี่เป็นการทดสอบตัวเอง"
    attrs = (C.c_uint * (len(thai) + 1))()
    language = function(pango, "pango_language_from_string", ptr, string)(b"th")
    function(pango, "pango_get_log_attrs", None, string, integer, integer, ptr, ptr, integer)(
        thai.encode(), len(thai.encode()), 0, language, attrs, len(attrs)
    )
    for boundary in [6, 11, 19, 22, 26, 29, 34]:
        assert attrs[boundary] & 1, ("Missing Thai line break", boundary)

    # Supply an empty fontconfig and exactly two fonts from Bazel runfiles.
    config = function(pango, "FcConfigCreate", ptr)()
    assert config
    # Pango requests the generic emoji family. Bind it explicitly to our
    # fixture, as a normal fontconfig installation does with its emoji rules.
    emoji_rule = b"""<fontconfig><match>
      <test name="family"><string>emoji</string></test>
      <edit name="family" mode="prepend" binding="strong"><string>Noto Color Emoji</string></edit>
      <edit name="lang" mode="prepend"><string>und-zsye</string></edit>
    </match></fontconfig>"""
    assert function(pango, "FcConfigParseAndLoadFromMemory", integer, ptr, string, integer)(config, emoji_rule, 1)
    assert function(pango, "FcConfigSetCurrent", integer, ptr)(config)
    assert function(pango, "FcConfigAppFontAddFile", integer, ptr, string)(config, os.fsencode(paths[3]))
    assert function(pango, "FcConfigAppFontAddFile", integer, ptr, string)(config, os.fsencode(paths[4]))
    set_config = function(ft2, "pango_fc_font_map_set_config", None, ptr, ptr)
    unref = function(pango, "g_object_unref", None, ptr)
    make_context = function(pango, "pango_font_map_create_context", ptr, ptr)
    make_layout = function(pango, "pango_layout_new", ptr, ptr)
    set_text = function(pango, "pango_layout_set_text", None, ptr, string, integer)
    measure = function(pango, "pango_layout_get_pixel_size", None, ptr, C.POINTER(integer), C.POINTER(integer))
    maps = [function(ft2, "pango_ft2_font_map_new", ptr)(), function(cairo, "pango_cairo_font_map_new", ptr)()]
    for index, font_map in enumerate(maps):
        assert font_map
        set_config(font_map, config)
        context = make_context(font_map)
        layout = make_layout(context)
        assert context and layout
        text = "Bazel Pango — العربية".encode()
        set_text(layout, text, len(text))
        width, height = integer(), integer()
        measure(layout, C.byref(width), C.byref(height))
        assert width.value > 0 and height.value > 0
        assert function(pango, "pango_layout_get_unknown_glyphs_count", integer, ptr)(layout) == 0
        if index == 1:
            surface = function(cairo, "cairo_image_surface_create", ptr, integer, integer, integer)(0, 512, 128)
            cr = function(cairo, "cairo_create", ptr, ptr)(surface)
            function(cairo, "pango_cairo_update_layout", None, ptr, ptr)(cr, layout)
            function(cairo, "pango_cairo_show_layout", None, ptr, ptr)(cr, layout)
            assert function(cairo, "cairo_status", integer, ptr)(cr) == 0
            function(cairo, "cairo_surface_flush", None, ptr)(surface)
            pixels = function(cairo, "cairo_image_surface_get_data", ptr, ptr)(surface)
            assert any(C.string_at(pixels, 512 * 128 * 4)), "No glyphs rendered"
            function(cairo, "cairo_destroy", None, ptr)(cr)
            function(cairo, "cairo_surface_destroy", None, ptr)(surface)
            # A font can resolve successfully yet render blank without PNG support.
            description = function(pango, "pango_font_description_from_string", ptr, string)(b"Noto Color Emoji 16")
            function(pango, "pango_layout_set_font_description", None, ptr, ptr)(layout, description)
            function(pango, "pango_font_description_free", None, ptr)(description)
            set_text(layout, "😀".encode(), -1)
            assert function(pango, "pango_layout_get_unknown_glyphs_count", integer, ptr)(layout) == 0
            surface = function(cairo, "cairo_image_surface_create", ptr, integer, integer, integer)(0, 512, 256)
            cr = function(cairo, "cairo_create", ptr, ptr)(surface)
            function(cairo, "pango_cairo_update_layout", None, ptr, ptr)(cr, layout)
            function(cairo, "pango_cairo_show_layout", None, ptr, ptr)(cr, layout)
            assert function(cairo, "cairo_status", integer, ptr)(cr) == 0
            function(cairo, "cairo_surface_flush", None, ptr)(surface)
            pixels = function(cairo, "cairo_image_surface_get_data", ptr, ptr)(surface)
            words = C.cast(pixels, C.POINTER(C.c_uint32))
            assert any(
                (word >> 24) and ((word & 255) != ((word >> 8) & 255) or (word & 255) != ((word >> 16) & 255))
                for word in words[: 512 * 256]
            ), "Color emoji produced no colored pixels"
            function(cairo, "cairo_destroy", None, ptr)(cr)
            function(cairo, "cairo_surface_destroy", None, ptr)(surface)
        unref(layout)
        unref(context)
        unref(font_map)
    function(pango, "FcConfigDestroy", None, ptr)(config)

    # Runtime proof that no host copy of this native stack was loaded.
    native_prefixes = (
        "libpango",
        "libcairo",
        "libglib",
        "libgobject",
        "libgio-",
        "libharfbuzz",
        "libfontconfig",
        "libfreetype",
        "libfribidi",
        "libpixman",
        "libpng",
        "libz.so",
        "libffi",
        "libpcre",
        "libexpat",
        "libthai",
        "libdatrie",
    )
    seen = set()
    for line in Path("/proc/self/maps").read_text().splitlines():
        path = line.split()[-1]
        if path.startswith("/") and Path(path).name.startswith(native_prefixes):
            loaded = Path(path).resolve()
            # Materialized runfiles may preserve aliases as hardlinks.
            matches = [expected for expected in paths[:3] if loaded.samefile(expected)]
            assert matches, f"Unexpected native library: {loaded}"
            seen.update(matches)
    assert seen == set(paths[:3]), seen
    print(f"Pango 1.56.3: dlopen order {first}, FT2 layout, Thai breaks and color emoji passed")


if __name__ == "__main__":
    main()
