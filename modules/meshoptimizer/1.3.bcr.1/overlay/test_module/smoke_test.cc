#include "meshoptimizer.h"

#include <cstdio>
#include <vector>

int main() {
  struct Vertex {
    float x, y, z;
  };

  // The first and the last vertex are identical, so the remap table must weld
  // them into a single unique vertex.
  const std::vector<Vertex> vertices = {
      {0.f, 0.f, 0.f}, {1.f, 0.f, 0.f}, {0.f, 0.f, 0.f}};

  std::vector<unsigned int> remap(vertices.size());
  const size_t unique_vertices = meshopt_generateVertexRemap(
      remap.data(), nullptr, vertices.size(), vertices.data(), vertices.size(),
      sizeof(Vertex));

  if (unique_vertices != 2) {
    std::printf("expected 2 unique vertices, got %zu\n", unique_vertices);
    return 1;
  }
  return 0;
}
