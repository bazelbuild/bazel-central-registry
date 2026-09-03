# Cairo 1.18.4.bcr.1

This additive build revision enables the upstream FreeType/fontconfig font
backend (`cairo-ft-font.c`, `cairo-colr-glyph-render.c`, and
`cairo-svg-glyph-render.c`) in the existing Cairo overlay. It supplies
`CAIRO_HAS_FT_FONT`, `CAIRO_HAS_FC_FONT` and the feature macros for the pinned
FreeType APIs. PangoCairo requires `cairo_ft_font_face_create_for_pattern` and
cannot use the original 1.18.4 BCR build, which has no platform font backend.
The upstream archive and Cairo version remain 1.18.4.

`@cairo//test:ft_smoke` renders a synthetic bitmap glyph through both the
FreeType-face and fontconfig-pattern APIs. It embeds its one-glyph font and
disables host fontconfig discovery, so it needs no installed fonts.

The configuration also declares `HAVE_ZLIB` for the existing zlib dependency,
so the script interpreter used by Cairo's presubmit compiles hermetically.

The existing Bazel test-path patch now formats its path through a mutable
local pointer before assigning the context field, so it compiles with GCC 14
without discarding pointer qualifiers. This only changes the test harness.
