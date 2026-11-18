#include <cstdio>
#include <cstring>
#include <filesystem>
#include <string>

#include "fastgltf/core.hpp"
#include "fastgltf/tools.hpp"
#include "fastgltf/types.hpp"

// A single triangle whose buffer is a base64 data URI, so parsing exercises
// simdjson and the base64 decoder without reading any files.
constexpr char kGltf[] = R"({
  "asset": {"version": "2.0"},
  "buffers": [{"byteLength": 36,
    "uri": "data:application/octet-stream;base64,AAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAA"}],
  "bufferViews": [{"buffer": 0, "byteLength": 36}],
  "accessors": [{"bufferView": 0, "componentType": 5126, "count": 3,
    "type": "VEC3", "min": [0, 0, 0], "max": [1, 1, 0]}],
  "meshes": [{"primitives": [{"attributes": {"POSITION": 0}}]}]
})";

int main() {
  auto data = fastgltf::GltfDataBuffer::FromBytes(
      reinterpret_cast<const std::byte*>(kGltf), std::strlen(kGltf));
  if (data.error() != fastgltf::Error::None) {
    std::printf("FromBytes failed\n");
    return 1;
  }
  fastgltf::Parser parser;
  auto asset = parser.loadGltfJson(data.get(), std::filesystem::path());
  if (asset.error() != fastgltf::Error::None) {
    std::printf("parse failed: %s\n",
                std::string(fastgltf::getErrorMessage(asset.error())).c_str());
    return 1;
  }
  if (fastgltf::validate(asset.get()) != fastgltf::Error::None) {
    std::printf("validation failed\n");
    return 1;
  }
  const fastgltf::Accessor& positions = asset->accessors[0];
  fastgltf::math::fvec3 p[3];
  fastgltf::copyFromAccessor<fastgltf::math::fvec3>(asset.get(), positions, p);
  // Expect (0,0,0), (1,0,0), (0,1,0).
  if (p[1].x() != 1.0f || p[2].y() != 1.0f || p[0].x() != 0.0f) {
    std::printf("unexpected positions\n");
    return 1;
  }
  return 0;
}
