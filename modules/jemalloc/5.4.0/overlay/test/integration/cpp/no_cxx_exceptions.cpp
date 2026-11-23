#include "test/jemalloc_test.h"

/*
 * Not upstream's. Makefile.in builds failing_new.cpp and infallible_new.cpp only where the C++ toolchain has
 * exceptions; where it does not, this build compiles this file in their place (see test/integration/BUILD.bazel).
 */
TEST_BEGIN(test_cxx_exceptions_unavailable) {
	test_skip("C++ exceptions are unavailable");
}
TEST_END

int
main(void) {
	return test(test_cxx_exceptions_unavailable);
}
