// An nm that fails, for private_namespace_gen's nm mode.

#include <iostream>

int main() {
    std::cerr << "fake_nm: cannot read archive member\n";
    return 1;
}
