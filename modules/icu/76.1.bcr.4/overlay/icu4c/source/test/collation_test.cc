// Verifies that the Collator API (which requires ICU data at runtime) works.

#include <cassert>
#include <cstdio>
#include <iostream>

#include <unicode/coll.h>
#include <unicode/unistr.h>

int main() {
    UErrorCode status = U_ZERO_ERROR;
    icu::Collator* coll =
        icu::Collator::createInstance(icu::Locale::getEnglish(), status);
    std::cout << "createInstance() status: " << u_errorName(status) << "\n";
    assert(U_SUCCESS(status));

    // "apple" < "banana" in English collation
    UCollationResult result =
        coll->compare(icu::UnicodeString("apple"), icu::UnicodeString("banana"), status);
    assert(U_SUCCESS(status));
    assert(result == UCOL_LESS);

    delete coll;
    std::printf("All collation_test assertions passed.\n");
    return 0;
}
