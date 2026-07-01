#ifndef EXCEPTION_TEST_H
#define EXCEPTION_TEST_H

#include <cxxtest/TestSuite.h>

#include <stdexcept>

class ExceptionTest : public CxxTest::TestSuite {
public:
    void test_throws_std_exception() {
        TS_ASSERT_THROWS(throw_runtime_error(), const std::runtime_error &);
    }

    void test_throws_anything() {
        TS_ASSERT_THROWS_ANYTHING(throw_runtime_error());
    }

    void test_throws_nothing() {
        TS_ASSERT_THROWS_NOTHING(safe_function());
    }

private:
    void throw_runtime_error() {
        throw std::runtime_error("expected");
    }

    void safe_function() {}
};

#endif  // EXCEPTION_TEST_H
