#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_CONFIG_OPTIONS_H

#ifndef FT_CONFIG_OPTION_USE_PNG
#error Public FreeType configuration must advertise PNG support
#endif
#include "rules_cc/cc/runfiles/runfiles.h"

#include <cstdio>
#include <memory>
#include <string>

#define CHECK(condition) do { if (!(condition)) { \
  std::fprintf(stderr, "Failed: %s at line %d\n", #condition, __LINE__); \
  return 1; } } while (0)

int main(int argc, char** argv) {
  CHECK(argc == 2);
  std::string error;
  std::unique_ptr<rules_cc::cc::runfiles::Runfiles> rf(
      rules_cc::cc::runfiles::Runfiles::CreateForTest(BAZEL_CURRENT_REPOSITORY, &error));
  CHECK(rf);
  const std::string font = rf->Rlocation(argv[1]);
  CHECK(!font.empty());
  FT_Library library;
  CHECK(FT_Init_FreeType(&library) == 0);
  FT_Face face;
  CHECK(FT_New_Face(library, font.c_str(), 0, &face) == 0);
  CHECK(FT_HAS_COLOR(face) && face->num_fixed_sizes > 0);
  CHECK(FT_Select_Size(face, 0) == 0);
  const FT_UInt glyph = FT_Get_Char_Index(face, 0x1F600);
  CHECK(glyph != 0);
  // This returns Unimplemented_Feature when FreeType's PNG option is off.
  CHECK(FT_Load_Glyph(face, glyph, FT_LOAD_COLOR | FT_LOAD_RENDER) == 0);
  const FT_Bitmap& bitmap = face->glyph->bitmap;
  CHECK(bitmap.pixel_mode == FT_PIXEL_MODE_BGRA);
  CHECK(bitmap.width > 0 && bitmap.rows > 0 && bitmap.pitch > 0);
  bool colored = false;
  for (unsigned y = 0; y < bitmap.rows; ++y) {
    const unsigned char* row = bitmap.buffer + y * bitmap.pitch;
    for (unsigned x = 0; x < bitmap.width; ++x) {
      const unsigned char* p = row + 4 * x;
      colored |= p[3] != 0 && (p[0] != p[1] || p[1] != p[2]);
    }
  }
  CHECK(colored);
  FT_Done_Face(face);
  FT_Done_FreeType(library);
  std::puts("PNG-backed color glyph loaded from Bazel runfiles");
  return 0;
}
