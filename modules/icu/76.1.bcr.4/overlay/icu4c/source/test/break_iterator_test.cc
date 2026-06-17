// Verifies that BreakIterator (which requires ICU data at runtime) works.

#include <cassert>
#include <cstdio>
#include <iostream>
#include <vector>

#include <unicode/brkiter.h>

int main() {
    UErrorCode status = U_ZERO_ERROR;
    icu::BreakIterator* bi =
        icu::BreakIterator::createWordInstance(icu::Locale::getUS(), status);
    std::cout << "createWordInstance() status: " << u_errorName(status) << "\n";
    assert(U_SUCCESS(status));

    bi->setText("the quick green froge");
    std::vector<int32_t> boundaries;
    int32_t p = bi->first();
    while (p != icu::BreakIterator::DONE) {
        std::cout << "Boundary at position: " << p << "\n";
        boundaries.push_back(p);
        p = bi->next();
    }
    delete bi;

    const std::vector<int32_t> want = {0, 3, 4, 9, 10, 15, 16, 21};
    assert(boundaries == want);

    std::printf("All break_iterator_test assertions passed.\n");
    return 0;
}
