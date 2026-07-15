#include <mujoco/mujoco.h>

#include <cmath>
#include <cstdio>

int main() {
  constexpr char kModel[] = R"(
    <mujoco>
      <option gravity="0 0 -9.81"/>
      <worldbody>
        <body pos="0 0 1">
          <freejoint/>
          <geom type="sphere" size="0.1" mass="1"/>
        </body>
      </worldbody>
    </mujoco>
  )";

  char error[1024] = {};
  mjSpec* spec = mj_parseXMLString(kModel, nullptr, error, sizeof(error));
  if (!spec) {
    std::fprintf(stderr, "mj_parseXMLString failed: %s\n", error);
    return 1;
  }

  mjModel* model = mj_compile(spec, nullptr);
  if (!model) {
    std::fprintf(stderr, "mj_compile failed\n");
    mj_deleteSpec(spec);
    return 1;
  }

  mjData* data = mj_makeData(model);
  if (!data) {
    std::fprintf(stderr, "mj_makeData failed\n");
    mj_deleteModel(model);
    mj_deleteSpec(spec);
    return 1;
  }

  const mjtNum initial_height = data->qpos[2];
  for (int i = 0; i < 10; ++i) {
    mj_step(model, data);
  }
  const bool fell = std::isfinite(data->qpos[2]) && data->qpos[2] < initial_height;

  mj_deleteData(data);
  mj_deleteModel(model);
  mj_deleteSpec(spec);
  return fell ? 0 : 1;
}
