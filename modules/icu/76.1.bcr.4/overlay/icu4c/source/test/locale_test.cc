// Verifies that locale resource loading (which requires ICU data) works.

#include <cassert>
#include <cstdio>
#include <iostream>

#include <unicode/locid.h>
#include <unicode/uloc.h>

int main() {
    // Basic locale creation.
    icu::Locale en = icu::Locale::getEnglish();
    assert(!en.isBogus());
    std::cout << "English locale: " << en.getName() << "\n";

    // Country / language accessors.
    icu::Locale fr("fr", "FR");
    assert(!fr.isBogus());
    std::cout << "French locale language: " << fr.getLanguage() << "\n";
    assert(std::string(fr.getLanguage()) == "fr");

    // uloc_countAvailable verifies that the ICU data (locale list) was loaded.
    int32_t n = uloc_countAvailable();
    std::cout << "Available locales: " << n << "\n";
    assert(n > 0);

    std::printf("All locale_test assertions passed.\n");
    return 0;
}
