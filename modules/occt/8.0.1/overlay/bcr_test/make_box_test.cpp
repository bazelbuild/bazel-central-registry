#include <BRepPrimAPI_MakeBox.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS_Shape.hxx>

#include <cstdio>

int main() {
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(1.0, 2.0, 3.0).Shape();

  int faces = 0;
  for (TopExp_Explorer it(box, TopAbs_FACE); it.More(); it.Next()) {
    ++faces;
  }

  if (faces != 6) {
    std::fprintf(stderr, "expected 6 faces, got %d\n", faces);
    return 1;
  }
  return 0;
}
