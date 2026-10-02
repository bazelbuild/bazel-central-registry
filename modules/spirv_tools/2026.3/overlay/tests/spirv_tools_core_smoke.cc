#include <cstdint>
#include <string>
#include <vector>

#include "spirv-tools/libspirv.hpp"

namespace {

constexpr char kMinimalModule[] = R"(OpCapability Shader
OpMemoryModel Logical GLSL450
%void = OpTypeVoid
%fn = OpTypeFunction %void
%main = OpFunction %void None %fn
%label = OpLabel
OpReturn
OpFunctionEnd
)";

}  // namespace

int main() {
  spvtools::SpirvTools tools(SPV_ENV_UNIVERSAL_1_0);
  if (!tools.IsValid()) {
    return 1;
  }

  std::vector<uint32_t> binary;
  if (!tools.Assemble(kMinimalModule, &binary)) {
    return 1;
  }

  std::string text;
  if (!tools.Disassemble(binary, &text, SPV_BINARY_TO_TEXT_OPTION_NO_HEADER)) {
    return 1;
  }

  return text.find("OpMemoryModel Logical GLSL450") != std::string::npos ? 0 : 1;
}
