#pragma once

static inline char *gettext(const char *m) {
    return (char *) m;
}

static inline char *dgettext(const char *d, const char *m) {
    (void) d;
    return (char *) m;
}

