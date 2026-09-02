/* MSVC stub for the POSIX `<langinfo.h>` header. Pulled in via the
   `:_msvc_langinfo_stub` cc_library on MSVC builds so `support/regex.h`
   et al. parse. Provides just the minimum gawk's vendored regex needs:
   `nl_item`, the `CODESET` selector, and a stub `nl_langinfo()`. */

#ifndef GAWK_MSVC_LANGINFO_STUB_H
#define GAWK_MSVC_LANGINFO_STUB_H

typedef int nl_item;
#define CODESET 0

static __inline char *nl_langinfo(nl_item _item) {
    /* MSVC's CRT exposes locale via `setlocale` / `localeconv`, not the
       POSIX `nl_langinfo` API. Hard-code UTF-8 here — the upstream
       `regcomp.c` codeset probe needs *some* answer; UTF-8 yields the
       correct path on modern Windows. */
    (void)_item;
    return "UTF-8";
}

#endif /* GAWK_MSVC_LANGINFO_STUB_H */
