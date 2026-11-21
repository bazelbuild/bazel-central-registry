// Loads a USDA layer from memory, writes it as USDA and reads it back, then reads upstream's
// models/cube.usdc and models/cube.usdz.
#include "rules_cc/cc/runfiles/runfiles.h"
#include "tinyusdz.hh"
#include "usda-writer.hh"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>

namespace {

using rules_cc::cc::runfiles::Runfiles;

constexpr char kUsda[] = R"(#usda 1.0
(
    defaultPrim = "World"
    upAxis = "Z"
)

def Xform "World"
{
    def Mesh "Triangle"
    {
        int[] faceVertexCounts = [3]
        int[] faceVertexIndices = [0, 1, 2]
        point3f[] points = [(0, 0, 0), (1, 0, 0), (0, 1, 0)]
    }
}
)";

bool Check(bool condition, const char* what, const std::string& err = "") {
  if (!condition) std::fprintf(stderr, "check failed: %s %s\n", what, err.c_str());
  return condition;
}

// /World (Xform) with the child /World/Triangle (Mesh).
bool HasTriangle(const tinyusdz::Stage& stage) {
  const auto& roots = stage.root_prims();
  if (roots.size() != 1 || roots[0].element_name() != "World") return false;
  const auto& children = roots[0].children();
  return children.size() == 1 && children[0].element_name() == "Triangle" &&
         children[0].as<tinyusdz::GeomMesh>() != nullptr;
}

bool HasMesh(const tinyusdz::Prim& prim) {
  if (prim.as<tinyusdz::GeomMesh>()) return true;
  for (const auto& child : prim.children()) {
    if (HasMesh(child)) return true;
  }
  return false;
}

bool HasMesh(const tinyusdz::Stage& stage) {
  for (const auto& prim : stage.root_prims()) {
    if (HasMesh(prim)) return true;
  }
  return false;
}

std::string TempPath(const char* name) {
  const char* dir = std::getenv("TEST_TMPDIR");
  return std::string(dir ? dir : ".") + "/" + name;
}

}  // namespace

int main(int argc, char** argv) {
  std::string warn;
  std::string err;
  bool ok = Check(argc == 3, "arguments: <cube.usdc> <cube.usdz>");

  tinyusdz::Stage stage;
  ok &= Check(tinyusdz::LoadUSDAFromMemory(reinterpret_cast<const uint8_t*>(kUsda), sizeof(kUsda) - 1, "", &stage,
                                           &warn, &err),
              "LoadUSDAFromMemory", err);
  ok &= Check(HasTriangle(stage), "prims of the USDA layer");

  const std::string usda_path = TempPath("triangle.usda");
  ok &= Check(tinyusdz::usda::SaveAsUSDA(usda_path, stage, &warn, &err), "SaveAsUSDA", err);
  tinyusdz::Stage from_usda;
  ok &= Check(tinyusdz::LoadUSDFromFile(usda_path, &from_usda, &warn, &err), "LoadUSDFromFile (USDA)", err);
  ok &= Check(HasTriangle(from_usda), "prims of the written USDA file");

  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(BAZEL_CURRENT_REPOSITORY, &error));
  if (!Check(runfiles != nullptr && argc == 3, "runfiles", error)) return 1;

  tinyusdz::Stage from_usdc;
  ok &= Check(tinyusdz::LoadUSDCFromFile(runfiles->Rlocation(argv[1]), &from_usdc, &warn, &err), "LoadUSDCFromFile",
              err);
  ok &= Check(HasMesh(from_usdc), "mesh in cube.usdc");

  tinyusdz::Stage from_usdz;
  ok &= Check(tinyusdz::LoadUSDZFromFile(runfiles->Rlocation(argv[2]), &from_usdz, &warn, &err), "LoadUSDZFromFile",
              err);
  ok &= Check(HasMesh(from_usdz), "mesh in cube.usdz");

  return ok ? 0 : 1;
}
