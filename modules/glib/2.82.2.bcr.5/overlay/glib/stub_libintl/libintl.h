#ifndef BCR_GLIB_OVERLAY_STUB_LIBINTL_H
#define BCR_GLIB_OVERLAY_STUB_LIBINTL_H

static inline char *gettext(const char *m) {
	return (char *) m;
}

static inline char *dgettext(const char *d, const char *m) {
	return (char *) m;
}

static inline char *dcgettext(const char *d, const char *m, int c) {
	return (char *) m;
}

static inline char *ngettext(const char *m1, const char *m2, unsigned long n) {
	return (char *) ((n == 1) ? m1 : m2);
}

static inline char *dngettext(const char *d, const char *m1, const char *m2, unsigned long n) {
	return (char *) ((n == 1) ? m1 : m2);
}

static inline char *dcngettext(const char *d, const char *m1, const char *m2, unsigned long n, int c) {
	return (char *) ((n == 1) ? m1 : m2);
}

static inline char *textdomain(const char *d) {
	return NULL;
}

static inline char *bindtextdomain(const char *d, const char *dir) {
	return (char *) "/";
}

static inline char *bind_textdomain_codeset(const char *d, const char *c) {
	return (char *) c;
}

#endif
