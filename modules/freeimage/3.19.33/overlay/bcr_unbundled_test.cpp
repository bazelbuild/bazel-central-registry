#ifndef NOMINMAX
#define NOMINMAX
#endif

// Include FreeImagePlus.h before FreeImage.h: on Windows, FreeImage.h defines
// _WINDOWS_ when <windows.h> has not yet been included, which would otherwise
// skip <windows.h> inside FreeImagePlus.h and leave HANDLE/HBITMAP/HWND/HDC
// undeclared.
#include "FreeImagePlus.h"
#include "FreeImage.h"

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <set>
#include <string>
#include <vector>

#define CHECK(cond)                                                            \
    do {                                                                       \
        if (!(cond)) {                                                         \
            std::fprintf(stderr, "CHECK failed at %s:%d: %s\n", __FILE__,      \
                         __LINE__, #cond);                                     \
            std::exit(1);                                                      \
        }                                                                      \
    } while (0)

namespace {

void SetAsciiTagKeyOnly(FIBITMAP* dib, FREE_IMAGE_MDMODEL model,
                        const char* key, const char* value) {
    FITAG* tag = FreeImage_CreateTag();
    CHECK(tag != nullptr);
    const DWORD len = static_cast<DWORD>(std::strlen(value) + 1);
    CHECK(FreeImage_SetTagKey(tag, key));
    CHECK(FreeImage_SetTagType(tag, FIDT_ASCII));
    CHECK(FreeImage_SetTagCount(tag, len));
    CHECK(FreeImage_SetTagLength(tag, len));
    CHECK(FreeImage_SetTagValue(tag, value));
    CHECK(FreeImage_SetMetadata(model, dib, key, tag));
    FreeImage_DeleteTag(tag);
}

void SetAsciiTagWithId(FIBITMAP* dib, FREE_IMAGE_MDMODEL model, WORD id,
                       const char* key, const char* value) {
    FITAG* tag = FreeImage_CreateTag();
    CHECK(tag != nullptr);
    const DWORD len = static_cast<DWORD>(std::strlen(value) + 1);
    CHECK(FreeImage_SetTagID(tag, id));
    CHECK(FreeImage_SetTagKey(tag, key));
    CHECK(FreeImage_SetTagType(tag, FIDT_ASCII));
    CHECK(FreeImage_SetTagCount(tag, len));
    CHECK(FreeImage_SetTagLength(tag, len));
    CHECK(FreeImage_SetTagValue(tag, value));
    CHECK(FreeImage_SetMetadata(model, dib, key, tag));
    FreeImage_DeleteTag(tag);
}

void ExpectAsciiTag(FIBITMAP* dib, FREE_IMAGE_MDMODEL model, const char* key,
                    const char* expected) {
    FITAG* tag = nullptr;
    CHECK(FreeImage_GetMetadata(model, dib, key, &tag));
    CHECK(tag != nullptr);
    CHECK(FreeImage_GetTagType(tag) == FIDT_ASCII);
    const char* actual = static_cast<const char*>(FreeImage_GetTagValue(tag));
    CHECK(actual != nullptr);
    CHECK(std::strcmp(actual, expected) == 0);
}

void TestSystemDependencies() {
    const std::set<std::string> expected = {
        "zlib",    "libpng", "libjpeg", "OpenJPEG",
        "libtiff", "WebP",   "OpenEXR", "Imath",
    };
    std::set<std::string> seen;
    const unsigned count = FreeImage_GetDependenciesCount();
    for (unsigned i = 0; i < count; ++i) {
        FI_DEPENDENCY_INFO info = {};
        CHECK(FreeImage_GetDependencyInfo(i, &info));
        CHECK(info.name != nullptr);
        CHECK(info.system_library == TRUE);
        const bool has_compiled =
            info.compiled_version != nullptr && *info.compiled_version != '\0';
        const bool has_runtime =
            info.runtime_version != nullptr && *info.runtime_version != '\0';
        CHECK(has_compiled || has_runtime);
        seen.insert(info.name);
    }
    CHECK(seen == expected);
}

void AppendLE16(std::vector<BYTE>& buf, uint16_t v) {
    buf.push_back(static_cast<BYTE>(v & 0xFF));
    buf.push_back(static_cast<BYTE>((v >> 8) & 0xFF));
}

void AppendLE32(std::vector<BYTE>& buf, uint32_t v) {
    buf.push_back(static_cast<BYTE>(v & 0xFF));
    buf.push_back(static_cast<BYTE>((v >> 8) & 0xFF));
    buf.push_back(static_cast<BYTE>((v >> 16) & 0xFF));
    buf.push_back(static_cast<BYTE>((v >> 24) & 0xFF));
}

void AppendIfdEntry(std::vector<BYTE>& buf, uint16_t tag, uint16_t type,
                    uint32_t count, uint32_t value_or_offset) {
    AppendLE16(buf, tag);
    AppendLE16(buf, type);
    AppendLE32(buf, count);
    AppendLE32(buf, value_or_offset);
}

void TestTiffExifMainMetadata() {
    // 1. Save & reload FIMD_EXIF_MAIN tags (both key-only and ID-populated).
    FIBITMAP* src = FreeImage_Allocate(16, 12, 24);
    CHECK(src != nullptr);
    SetAsciiTagKeyOnly(src, FIMD_EXIF_MAIN, "ImageDescription",
                       "BCR TIFF Description");
    SetAsciiTagKeyOnly(src, FIMD_EXIF_MAIN, "Artist", "BCR Author");
    SetAsciiTagWithId(src, FIMD_EXIF_MAIN, 0x010F, "Make", "Bazel");
    SetAsciiTagWithId(src, FIMD_EXIF_MAIN, 0x0110, "Model", "BCR");
    SetAsciiTagWithId(src, FIMD_EXIF_MAIN, 0x0131, "Software",
                      "FreeImage 3.19.33");
    SetAsciiTagWithId(src, FIMD_EXIF_MAIN, 0x8298, "Copyright",
                      "Copyright 2026");

    FIMEMORY* mem = FreeImage_OpenMemory();
    CHECK(mem != nullptr);
    CHECK(FreeImage_SaveToMemory(FIF_TIFF, src, mem, TIFF_DEFAULT));
    FreeImage_Unload(src);

    CHECK(FreeImage_SeekMemory(mem, 0, SEEK_SET));
    FIBITMAP* loaded = FreeImage_LoadFromMemory(FIF_TIFF, mem, 0);
    CHECK(loaded != nullptr);

    ExpectAsciiTag(loaded, FIMD_EXIF_MAIN, "ImageDescription",
                   "BCR TIFF Description");
    ExpectAsciiTag(loaded, FIMD_EXIF_MAIN, "Artist", "BCR Author");
    ExpectAsciiTag(loaded, FIMD_EXIF_MAIN, "Make", "Bazel");
    ExpectAsciiTag(loaded, FIMD_EXIF_MAIN, "Model", "BCR");
    ExpectAsciiTag(loaded, FIMD_EXIF_MAIN, "Software", "FreeImage 3.19.33");
    ExpectAsciiTag(loaded, FIMD_EXIF_MAIN, "Copyright", "Copyright 2026");

    // Verify core non-FIELD_CUSTOM TIFFTAG_* fields are also read into FIMD_EXIF_MAIN.
    FITAG* width_tag = nullptr;
    CHECK(FreeImage_GetMetadata(FIMD_EXIF_MAIN, loaded, "ImageWidth", &width_tag));
    CHECK(width_tag != nullptr);
    CHECK(*static_cast<const uint32_t*>(FreeImage_GetTagValue(width_tag)) == 16u);

    FreeImage_Unload(loaded);
    FreeImage_CloseMemory(mem);

    // 2. Load a minimal 1x1 8-bit grayscale TIFF with explicit TIFFTAG_ORIENTATION = 6.
    std::vector<BYTE> tiff_bytes = {'I', 'I', 42, 0, 8, 0, 0, 0};
    const uint16_t num_entries = 9;
    const uint32_t pixel_offset = 8 + 2 + num_entries * 12 + 4;
    AppendLE16(tiff_bytes, num_entries);
    AppendIfdEntry(tiff_bytes, 0x0100, 4, 1, 1);             // ImageWidth = 1
    AppendIfdEntry(tiff_bytes, 0x0101, 4, 1, 1);             // ImageLength = 1
    AppendIfdEntry(tiff_bytes, 0x0102, 3, 1, 8);             // BitsPerSample = 8
    AppendIfdEntry(tiff_bytes, 0x0103, 3, 1, 1);             // Compression = NONE
    AppendIfdEntry(tiff_bytes, 0x0106, 3, 1, 1);             // Photometric = MINISBLACK
    AppendIfdEntry(tiff_bytes, 0x0111, 4, 1, pixel_offset);  // StripOffsets
    AppendIfdEntry(tiff_bytes, 0x0112, 3, 1, 6);             // Orientation = 6
    AppendIfdEntry(tiff_bytes, 0x0115, 3, 1, 1);             // SamplesPerPixel = 1
    AppendIfdEntry(tiff_bytes, 0x0117, 4, 1, 1);             // StripByteCounts = 1
    AppendLE32(tiff_bytes, 0);                               // Next IFD = 0
    tiff_bytes.push_back(0x7F);                              // 1 pixel

    FIMEMORY* orient_mem =
        FreeImage_OpenMemory(tiff_bytes.data(), static_cast<DWORD>(tiff_bytes.size()));
    CHECK(orient_mem != nullptr);
    FIBITMAP* orient_dib = FreeImage_LoadFromMemory(FIF_TIFF, orient_mem, 0);
    CHECK(orient_dib != nullptr);
    FITAG* orient_tag = nullptr;
    CHECK(FreeImage_GetMetadata(FIMD_EXIF_MAIN, orient_dib, "Orientation",
                                &orient_tag));
    CHECK(orient_tag != nullptr);
    CHECK(*static_cast<const uint16_t*>(FreeImage_GetTagValue(orient_tag)) == 6u);
    FreeImage_Unload(orient_dib);
    FreeImage_CloseMemory(orient_mem);
}

unsigned DLL_CALLCONV MemRead(void* buf, unsigned sz, unsigned cnt,
                              fi_handle h) {
    return FreeImage_ReadMemory(buf, sz, cnt, static_cast<FIMEMORY*>(h));
}

unsigned DLL_CALLCONV MemWrite(void* buf, unsigned sz, unsigned cnt,
                               fi_handle h) {
    return FreeImage_WriteMemory(buf, sz, cnt, static_cast<FIMEMORY*>(h));
}

int DLL_CALLCONV MemSeek(fi_handle h, long off, int origin) {
    return FreeImage_SeekMemory(static_cast<FIMEMORY*>(h), off, origin) ? 0
                                                                        : -1;
}

long DLL_CALLCONV MemTell(fi_handle h) {
    return FreeImage_TellMemory(static_cast<FIMEMORY*>(h));
}

void TestCodecsAndFreeImagePlus() {
    // OpenEXR (FIT_RGBAF) round-trip.
    FIBITMAP* exr = FreeImage_AllocateT(FIT_RGBAF, 4, 4);
    CHECK(exr != nullptr);
    FIRGBAF* row = reinterpret_cast<FIRGBAF*>(FreeImage_GetScanLine(exr, 0));
    row[0] = {1.5f, 0.25f, 2.0f, 0.75f};
    FIMEMORY* exr_mem = FreeImage_OpenMemory();
    CHECK(FreeImage_SaveToMemory(FIF_EXR, exr, exr_mem, EXR_FLOAT));
    FreeImage_Unload(exr);
    CHECK(FreeImage_SeekMemory(exr_mem, 0, SEEK_SET));
    FIBITMAP* exr_loaded = FreeImage_LoadFromMemory(FIF_EXR, exr_mem, 0);
    CHECK(exr_loaded != nullptr && FreeImage_GetImageType(exr_loaded) == FIT_RGBAF);
    const FIRGBAF* loaded_row =
        reinterpret_cast<const FIRGBAF*>(FreeImage_GetScanLine(exr_loaded, 0));
    CHECK(std::fabs(loaded_row[0].red - 1.5f) < 1e-5f);
    CHECK(std::fabs(loaded_row[0].alpha - 0.75f) < 1e-5f);
    FreeImage_Unload(exr_loaded);
    FreeImage_CloseMemory(exr_mem);

    // WebP lossless, JP2, progressive JPEG, and lossless JPEG rotation via FreeImagePlus.
    fipImage img(FIT_BITMAP, 64, 48, 24);
    CHECK(img.isValid());
    img.getScanLine(0)[0] = 123;

    fipMemoryIO webp_io;
    CHECK(img.saveToMemory(FIF_WEBP, webp_io, WEBP_LOSSLESS));
    webp_io.seek(0, SEEK_SET);
    fipImage webp_loaded;
    CHECK(webp_loaded.loadFromMemory(webp_io));
    CHECK(webp_loaded.getWidth() == 64 && webp_loaded.getHeight() == 48);
    CHECK(webp_loaded.getScanLine(0)[0] == 123);

    fipMemoryIO jp2_io;
    CHECK(img.saveToMemory(FIF_JP2, jp2_io, JP2_DEFAULT));
    jp2_io.seek(0, SEEK_SET);
    fipImage jp2_loaded;
    CHECK(jp2_loaded.loadFromMemory(jp2_io));
    CHECK(jp2_loaded.getWidth() == 64 && jp2_loaded.getHeight() == 48);

    fipMemoryIO jpg_io;
    CHECK(img.saveToMemory(FIF_JPEG, jpg_io,
                           JPEG_QUALITYSUPERB | JPEG_PROGRESSIVE));
    jpg_io.seek(0, SEEK_SET);
    // Exercise lossless JPEG rotation (transupp.h) using memory handles.
    BYTE* jpg_data = nullptr;
    DWORD jpg_size = 0;
    CHECK(jpg_io.acquire(&jpg_data, &jpg_size) && jpg_size > 0);
    FIMEMORY* src_mem = FreeImage_OpenMemory(jpg_data, jpg_size);
    FIMEMORY* dst_mem = FreeImage_OpenMemory();
    FreeImageIO fi_io = {MemRead, MemWrite, MemSeek, MemTell};
    CHECK(FreeImage_JPEGTransformFromHandle(&fi_io, src_mem, &fi_io, dst_mem,
                                            FIJPEG_OP_ROTATE_90, nullptr,
                                            nullptr, nullptr, FALSE));
    CHECK(FreeImage_SeekMemory(dst_mem, 0, SEEK_SET));
    FIBITMAP* rotated = FreeImage_LoadFromMemory(FIF_JPEG, dst_mem, 0);
    CHECK(rotated != nullptr);
    CHECK(FreeImage_GetWidth(rotated) == 48 && FreeImage_GetHeight(rotated) == 64);
    FreeImage_Unload(rotated);
    FreeImage_CloseMemory(dst_mem);
    FreeImage_CloseMemory(src_mem);

    // ZLib helper round-trip.
    const char payload[] = "bazel-central-registry-zlib-roundtrip-payload";
    BYTE compressed[256] = {};
    const DWORD comp_len = FreeImage_ZLibCompress(
        compressed, sizeof(compressed),
        reinterpret_cast<BYTE*>(const_cast<char*>(payload)), sizeof(payload));
    CHECK(comp_len > 0);
    BYTE decompressed[256] = {};
    const DWORD decomp_len = FreeImage_ZLibUncompress(
        decompressed, sizeof(decompressed), compressed, comp_len);
    CHECK(decomp_len == sizeof(payload));
    CHECK(std::memcmp(decompressed, payload, sizeof(payload)) == 0);
}

}  // namespace

int main() {
    FreeImage_Initialise();
    TestSystemDependencies();
    TestTiffExifMainMetadata();
    TestCodecsAndFreeImagePlus();
    FreeImage_DeInitialise();
    std::puts("BCR unbundled dependencies, TIFF FIMD_EXIF_MAIN metadata, and codec checks passed");
    return 0;
}
