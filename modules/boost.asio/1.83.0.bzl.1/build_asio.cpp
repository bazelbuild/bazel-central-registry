// Per
// https://www.boost.org/doc/libs/1_72_0/doc/html/boost_asio/using.html#boost_asio.using.optional_separate_compilation,
// exactly one file in an ASIO project using separate compilation must
// contain the following #include. See also
// https://github.com/nelhage/rules_boost/issues/166 and
// https://github.com/nelhage/rules_boost/issues/170
#include "boost/asio/impl/src.hpp"
