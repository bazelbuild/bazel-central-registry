# FreeType 2.14.1.bcr.1

Enables the existing upstream PNG bitmap glyph support with
`FT_CONFIG_OPTION_USE_PNG` and the BCR `libpng` dependency. This fixes
`FT_Load_Glyph(..., FT_LOAD_COLOR | FT_LOAD_RENDER)` returning
`Unimplemented_Feature` for PNG-backed color fonts. The upstream FreeType
source release remains 2.14.1; no source patch or host configuration runs.

The public target remains `@freetype//:freetype`.

The consumer test downloads Pango 1.52.1's small Noto Color Emoji subset
with a pinned SHA-256, resolves it through Bazel runfiles, and checks that
U+1F600 produces a nonempty colored BGRA bitmap. It does not use host fonts.
The existing build-platform matrix is retained; the test adds coverage
for Bazel 7, 8, and 9 on Linux, macOS arm64, and Windows.

The source URL uses Savannah's direct release mirror instead of its download
redirector, which returned HTTP 502 in BCR CI. This URL was already listed as
a mirror in the previous registry revision. The archive checksum and the
other direct mirrors are unchanged.
