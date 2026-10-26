#include <hermes/hermes.h>

#include <iostream>
#include <memory>

int main() {
  // JSError retains runtime values until its catch handler finishes.
  std::unique_ptr<facebook::hermes::HermesRuntime> runtime;
  try {
    runtime = facebook::hermes::makeHermesRuntime();
    auto result = runtime->evaluateJavaScript(
        std::make_shared<facebook::jsi::StringBuffer>(
            "JSON.stringify([1, 2].map(x => x + 1)) === '[2,3]' && "
            "Promise.resolve(42) instanceof Promise && "
            "/\\p{Letter}/u.test('A')"),
        "smoke.js");
    return result.isBool() && result.getBool() ? 0 : 1;
  } catch (const std::exception &error) {
    std::cerr << error.what() << '\n';
    return 1;
  }
}
