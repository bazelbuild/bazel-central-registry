#include "spirv-tools/optimizer.hpp"

int main() {
  spvtools::Optimizer optimizer(SPV_ENV_UNIVERSAL_1_0);
  optimizer.RegisterPass(spvtools::CreateCompactIdsPass());
  optimizer.SetMessageConsumer([](spv_message_level_t, const char*, const spv_position_t&, const char*) {});
  return 0;
}
