// Round-trips a small Gaussian cloud through SPZ (in memory and as a file) and PLY, and compares
// it within the quantization of the packed format. With --@spz//:extensions=True the
// SPZ_ADOBE_safe_orbit_camera extension is round-tripped as well.
#include "load-spz.h"
#ifdef SPZ_BUILD_EXTENSIONS
#include "safe-orbit-camera-adobe.h"
#endif

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>
#include <vector>

namespace {

bool Check(bool condition, const char* what) {
  if (!condition) std::fprintf(stderr, "check failed: %s\n", what);
  return condition;
}

bool Near(const std::vector<float>& actual, const std::vector<float>& expected, float tolerance) {
  if (actual.size() != expected.size()) return false;
  for (size_t i = 0; i < actual.size(); ++i) {
    if (std::fabs(actual[i] - expected[i]) > tolerance) return false;
  }
  return true;
}

spz::GaussianCloud MakeCloud() {
  spz::GaussianCloud cloud;
  cloud.numPoints = 2;
  cloud.shDegree = 1;
  cloud.positions = {0.0f, 0.5f, -1.0f, 1.25f, -0.75f, 2.0f};
  cloud.scales = {-2.0f, -1.5f, -1.0f, -0.5f, -0.25f, 0.0f};
  cloud.rotations = {0.0f, 0.0f, 0.0f, 1.0f, 0.5f, 0.5f, 0.5f, 0.5f};  // x, y, z, w
  cloud.alphas = {-1.0f, 2.0f};
  cloud.colors = {0.1f, -0.2f, 0.3f, -0.4f, 0.5f, -0.6f};
  cloud.sh = {0.10f, -0.10f, 0.20f, -0.20f, 0.30f, -0.30f, 0.05f, -0.05f, 0.15f,
              -0.15f, 0.25f, -0.25f, 0.35f, -0.35f, 0.00f, 0.10f, -0.10f, 0.20f};
  return cloud;
}

// Tolerances of the packed format: 12 fractional bits for positions, 8 bits for scales, alphas and
// colors, 5 bits for degree 1 spherical harmonics, smallest three components for rotations.
bool MatchesPacked(const spz::GaussianCloud& actual, const spz::GaussianCloud& expected) {
  bool ok = Check(actual.numPoints == expected.numPoints, "numPoints");
  ok &= Check(actual.shDegree == expected.shDegree, "shDegree");
  ok &= Check(Near(actual.positions, expected.positions, 1e-3f), "positions");
  ok &= Check(Near(actual.scales, expected.scales, 0.05f), "scales");
  ok &= Check(Near(actual.rotations, expected.rotations, 0.01f), "rotations");
  ok &= Check(Near(actual.alphas, expected.alphas, 0.05f), "alphas");
  ok &= Check(Near(actual.colors, expected.colors, 0.03f), "colors");
  ok &= Check(Near(actual.sh, expected.sh, 0.05f), "sh");
  return ok;
}

std::string TempPath(const char* name) {
  const char* dir = std::getenv("TEST_TMPDIR");
  return std::string(dir ? dir : ".") + "/" + name;
}

}  // namespace

int main() {
  spz::GaussianCloud cloud = MakeCloud();
#ifdef SPZ_BUILD_EXTENSIONS
  auto camera = std::make_shared<spz::SpzExtensionSafeOrbitCameraAdobe>();
  camera->safeOrbitElevationMin = -0.5f;
  camera->safeOrbitElevationMax = 1.0f;
  camera->safeOrbitRadiusMin = 2.5f;
  cloud.extensions.push_back(camera);
  bool ok = Check(spz::hasExtensionSupport(), "hasExtensionSupport");
#else
  bool ok = Check(!spz::hasExtensionSupport(), "hasExtensionSupport");
#endif

  std::vector<uint8_t> bytes;
  ok &= Check(spz::saveSpz(cloud, spz::PackOptions{}, &bytes) && !bytes.empty(), "saveSpz to memory");
  ok &= Check(spz::loadSpzPacked(bytes).version == spz::LATEST_SPZ_HEADER_VERSION, "packed version");
  const spz::GaussianCloud loaded = spz::loadSpz(bytes, spz::UnpackOptions{});
  ok &= MatchesPacked(loaded, cloud);
#ifdef SPZ_BUILD_EXTENSIONS
  auto loaded_camera = spz::findExtensionByType<spz::SpzExtensionSafeOrbitCameraAdobe>(loaded.extensions);
  ok &= Check(loaded_camera && loaded_camera->safeOrbitElevationMin == -0.5f &&
                  loaded_camera->safeOrbitElevationMax == 1.0f && loaded_camera->safeOrbitRadiusMin == 2.5f,
              "safe orbit camera extension");
#endif

  const std::string spz_path = TempPath("cloud.spz");
  ok &= Check(spz::saveSpz(cloud, spz::PackOptions{}, spz_path), "saveSpz to file");
  ok &= MatchesPacked(spz::loadSpz(spz_path, spz::UnpackOptions{}), cloud);

  // PLY stores 32-bit floats.
  const std::string ply_path = TempPath("cloud.ply");
  ok &= Check(spz::saveSplatToPly(cloud, spz::PackOptions{}, ply_path), "saveSplatToPly");
  const spz::GaussianCloud from_ply = spz::loadSplatFromPly(ply_path, spz::UnpackOptions{});
  ok &= Check(from_ply.numPoints == cloud.numPoints && Near(from_ply.positions, cloud.positions, 1e-6f) &&
                  Near(from_ply.sh, cloud.sh, 1e-6f),
              "PLY round trip");

  return ok ? 0 : 1;
}
