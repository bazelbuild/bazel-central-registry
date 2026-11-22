#include "test/jemalloc_test.h"

/*
 * Not upstream's (see test/integration/BUILD.bazel). thread.allocated counts the bytes jemalloc allocates on this
 * thread, so it moves across ::operator new only if jemalloc's operator new is the one linked.
 */
TEST_BEGIN(test_operator_new_owned) {
	uint64_t before, after;
	size_t   sz = sizeof(before);

	expect_d_eq(mallctl("thread.allocated", (void *)&before, &sz, NULL, 0),
	    0, "Unexpected mallctl failure reading thread.allocated");
	void *volatile ptr = ::operator new((size_t)64);
	expect_d_eq(mallctl("thread.allocated", (void *)&after, &sz, NULL, 0),
	    0, "Unexpected mallctl failure reading thread.allocated");
	::operator delete(ptr);
	expect_u64_ge(after - before, 64,
	    "::operator new did not allocate from jemalloc");
}
TEST_END

int
main(void) {
	return test(test_operator_new_owned);
}
