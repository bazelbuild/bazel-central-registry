/*
  A POSIX <regex.h> whose regcomp, regexec, regerror and regfree are TRE's.

  regex_t and regmatch_t are TRE's own types, taken from <tre/tre.h>. Nothing
  here describes the platform's regex layout, which is what lets these four
  declarations be written out by hand.

  HAZARD: a translation unit compiled against this header must never be linked
  beside one compiled against the platform's <regex.h>. The two regex_t layouts
  are unrelated, so an object handed across that boundary is undefined
  behaviour that nothing at compile or link time can diagnose. Either the whole
  link unit takes its regex from here or none of it does.

  This header's guard is namespaced on purpose rather than spelled _REGEX_H,
  the name glibc's own <regex.h> uses and the one the libsystre header credited
  in posix.c adopted for drop-in compatibility. Sharing it would make the two
  headers mutually exclusive within a translation unit: whichever arrived first
  would win and the second would expand to nothing, so a source including the
  platform header and then this one would compile clean and end up with glibc's
  regex_t while calling forwarders that write TRE's. Distinct guards make that
  source fail on the conflicting regex_t instead. That is the one face of the
  hazard above a compiler can see, and the diagnostic is worth more than the
  quiet.
*/

#ifndef TRE_POSIX_REGEX_H
#define TRE_POSIX_REGEX_H 1

#include <stddef.h>

#include <tre/tre.h>

#ifdef __cplusplus
extern "C" {
#endif

extern int
regcomp(regex_t *preg, const char *regex, int cflags);

extern int
regexec(const regex_t *preg, const char *string, size_t nmatch,
        regmatch_t pmatch[], int eflags);

extern size_t
regerror(int errcode, const regex_t *preg, char *errbuf, size_t errbuf_size);

extern void
regfree(regex_t *preg);

#ifdef __cplusplus
}
#endif

#endif /* TRE_POSIX_REGEX_H */
