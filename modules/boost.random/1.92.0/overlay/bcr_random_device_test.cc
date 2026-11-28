#include <boost/random/random_device.hpp>

int main() {
    boost::random::random_device random;
    (void)random();
    return 0;
}
