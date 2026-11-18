/*
  The counterpart to the drop-in test: @tre alone must not put a bare regex.h on
  a consumer's include path nor define the unprefixed POSIX symbols, or every
  consumer of the library silently has its regex replaced.

  Proved two ways, neither portable alone. At compile time, TRE's <tre/regex.h>
  defines regcomp as a macro and :posix's header drags in TRE-only names, so
  either being visible means a leak.

  At run time, two probes. "(foobar){~1}" discriminates only where approximate
  matching is compiled in: glibc rejects it as invalid {} content and a
  BSD-derived libc reads the "{" literally and matches the text "foobar{~1}",
  both accepted below, but under --@tre//:approx=false leaked TRE symbols would
  compile it and fail to match, passing for the wrong reason. "\d"
  (lib/tre-parse.c:53-63) is flag-independent and carries the check there. No
  error code is asserted, for the same portability reason.

  musl's regex is itself a TRE fork (src/regex/regcomp.c:2) with the same \d
  table, so no pattern discriminates there at all.
*/

#include <stdio.h>

#include <regex.h>

#if defined(regcomp) || defined(REG_APPROX_MATCHER)
#error "a TRE regex.h is reachable from @tre; the bare header leaked onto the include path"
#endif

int main(void) {
  regex_t preg;
  regmatch_t pmatch[1];

  if (regcomp(&preg, "\\d", REG_EXTENDED) == 0) {
    int digit_matched = regexec(&preg, "7", 1, pmatch, 0) == 0;

    regfree(&preg);
    if (digit_matched) {
      fputs("FAIL: unprefixed regexec matched \"\\d\" against \"7\". Either @tre is\n"
            "      exporting the POSIX symbols, or this platform's libc is itself\n"
            "      TRE-derived -- musl's regex is a TRE fork carrying the same \\d macro\n"
            "      table -- in which case this test cannot tell the two apart and does\n"
            "      not apply here\n",
            stderr);
      return 1;
    }
  }

  if (regcomp(&preg, "(foobar){~1}", REG_EXTENDED) != 0) {
    printf("posix isolation OK: \"\\d\" is a literal here and the platform regcomp rejected\n"
           "TRE syntax\n");
    return 0;
  }
  if (regexec(&preg, "xx fuobar xx", 1, pmatch, 0) == 0) {
    fprintf(stderr,
            "FAIL: unprefixed regexec produced a TRE approximate match at [%d,%d);\n"
            "      @tre is exporting the POSIX symbols\n",
            (int)pmatch[0].rm_so, (int)pmatch[0].rm_eo);
    regfree(&preg);
    return 1;
  }
  regfree(&preg);

  printf("posix isolation OK: \"\\d\" is a literal here and \"{~1}\" was read literally too\n");
  return 0;
}
