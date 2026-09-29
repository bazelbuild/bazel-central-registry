#include <thai/thbrk.h>
#include <thai/thwbrk.h>
#include <thai/thwchar.h>
#include <stdio.h>
#include <stdlib.h>

#define CHECK(condition) do { if (!(condition)) { \
    fprintf(stderr, "Failed: %s at line %d\n", #condition, __LINE__); \
    return 1; } } while (0)

/* This consumer has no dictionary in data and does not resolve runfiles. */
int main(void) {
    CHECK(unsetenv("LIBTHAI_DICTDIR") == 0);
    const thwchar_t text[] = L"สวัสดีครับ กอ.รมน. นี่เป็นการทดสอบตัวเอง";
    const int expected[] = {6, 11, 19, 22, 26, 29, 34};
    thchar_t tis[40];
    unsigned i;
    for (i = 0; text[i]; ++i) tis[i] = th_uni2tis(text[i]);
    tis[i] = 0;
    ThBrk *brk = th_brk_new(NULL);
    CHECK(brk);
    int positions[40] = {0};
    CHECK(th_brk_find_breaks(brk, tis, positions, 40) == 7);
    for (i = 0; i < 7; ++i) CHECK(positions[i] == expected[i]);
    th_brk_delete(brk);
    /* Pango calls this default API rather than opening a dictionary itself. */
    CHECK(th_brk(tis, positions, 40) == 7);
    for (i = 0; i < 7; ++i) CHECK(positions[i] == expected[i]);
    CHECK(th_wbrk(text, positions, 40) == 7);
    for (i = 0; i < 7; ++i) CHECK(positions[i] == expected[i]);
    /* Preserve upstream's fallback when an environment override is missing. */
    CHECK(setenv("LIBTHAI_DICTDIR", "/nonexistent/libthai", 1) == 0);
    brk = th_brk_new(NULL);
    CHECK(brk);
    CHECK(th_brk_find_breaks(brk, tis, positions, 40) == 7);
    for (i = 0; i < 7; ++i) CHECK(positions[i] == expected[i]);
    th_brk_delete(brk);
    return 0;
}
