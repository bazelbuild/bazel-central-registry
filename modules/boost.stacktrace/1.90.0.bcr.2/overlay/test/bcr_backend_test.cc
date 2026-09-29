#include <boost/stacktrace.hpp>

#include <iostream>

int main() {
    const boost::stacktrace::stacktrace trace;
    std::cout << trace;

#ifdef BOOST_STACKTRACE_USE_NOOP
    return trace.empty() ? 0 : 1;
#else
    return trace.empty() ? 1 : 0;
#endif
}
