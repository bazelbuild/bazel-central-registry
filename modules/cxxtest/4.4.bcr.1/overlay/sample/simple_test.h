#ifndef SIMPLE_TEST_H
#define SIMPLE_TEST_H

#include <cxxtest/TestSuite.h>

class SimpleTest : public CxxTest::TestSuite {
public:
    void test_equality() {
        TS_ASSERT_EQUALS(1, 1);
        TS_ASSERT_EQUALS(2 + 2, 4);
    }

    void test_comparison() {
        TS_ASSERT_LESS_THAN(1, 2);
        TS_ASSERT_DIFFERS(1, 2);
    }

    void test_truth() {
        TS_ASSERT(true);
        TS_ASSERT_DIFFERS(0, 1);
    }
};

#endif  // SIMPLE_TEST_H
