#include <cassert>
#include <iostream>
#include <vector>

#include <unicode/brkiter.h>

int main()
{
    UErrorCode status = U_ZERO_ERROR;
    icu::BreakIterator *bi = icu::BreakIterator::createWordInstance(icu::Locale::getUS(), status);
    std::cout << "createWordInstance() status: " << u_errorName(status) << std::endl;
    assert(U_SUCCESS(status));

    bi->setText("the quick green froge");
    std::vector<int> boundaries;
    int32_t p = bi->first();
    while (p != icu::BreakIterator::DONE)
    {
        std::cout << "Boundary at position: " << p << std::endl;
        boundaries.push_back(p);
        p = bi->next();
    }
    delete bi;

    std::vector<int> want_boundaries = {0, 3, 4, 9, 10, 15, 16, 21};
    assert(boundaries == want_boundaries);

    printf("All tests passed!\n");
    return 0;
}
