#include <stdexec/execution.hpp>

int main() {
    auto work = stdexec::just(2) | stdexec::then([](int value) { return value * value; });
    auto result = stdexec::sync_wait(std::move(work));
    return result.has_value() && std::get<0>(*result) == 4 ? 0 : 1;
}
