/*
  @tre//:posix as a drop-in. Every call below is ordinary POSIX; the patterns
  are what discriminate.

  "\d" is TRE's shorthand for the digit class (lib/tre-parse.c:53-63) and the
  parser expands it with no reference to any build option, so it discriminates
  whatever the library was configured with. "(foobar){~1}" does not: under
  --@tre//:approx=false the parser still accepts the syntax and only the
  matcher goes away, so it is guarded on TRE_APPROX -- readable here because
  <regex.h> reaches <tre/tre.h> and with it the generated tre-config.h.
*/

#include <stdio.h>

#include <regex.h>

int main(void) {
  regex_t preg;
  regmatch_t pmatch[1];
  char errbuf[128];
  int rc;

  if (regcomp(&preg, "\\d", REG_EXTENDED) != 0) {
    fputs("FAIL: regcomp rejected \"\\d\"; <regex.h> or the regcomp symbol did not come\n"
          "      from @tre//:posix\n",
          stderr);
    return 1;
  }
  if (regexec(&preg, "7", 1, pmatch, 0) != 0) {
    fputs("FAIL: \"\\d\" did not match \"7\", so the escape was read as a literal \"d\";\n"
          "      the symbols came from the platform and not from @tre//:posix\n",
          stderr);
    regfree(&preg);
    return 1;
  }
  regfree(&preg);

#ifdef TRE_APPROX
  if (regcomp(&preg, "(foobar){~1}", REG_EXTENDED) != 0) {
    fputs("FAIL: regcomp rejected approximate-matching syntax\n", stderr);
    return 1;
  }
  if (regexec(&preg, "xx fuobar xx", 1, pmatch, 0) != 0) {
    fputs("FAIL: regexec found no approximate match for \"fuobar\"\n", stderr);
    regfree(&preg);
    return 1;
  }
  if (pmatch[0].rm_so != 3 || pmatch[0].rm_eo != 9) {
    fprintf(stderr, "FAIL: expected the approximate match at [3,9), got [%d,%d)\n",
            (int)pmatch[0].rm_so, (int)pmatch[0].rm_eo);
    regfree(&preg);
    return 1;
  }
  regfree(&preg);
  printf("posix drop-in: approximate match at [3,9)\n");
#endif

  rc = regcomp(&preg, "(", REG_EXTENDED);
  if (rc == 0) {
    fputs("FAIL: regcomp accepted an unbalanced \"(\"\n", stderr);
    regfree(&preg);
    return 1;
  }
  errbuf[0] = '\0';
  if (regerror(rc, &preg, errbuf, sizeof(errbuf)) < 2 || errbuf[0] == '\0') {
    fputs("FAIL: regerror produced no message for a rejected pattern\n", stderr);
    return 1;
  }

  printf("posix drop-in OK: \"\\d\" matched a digit, regerror says \"%s\"\n", errbuf);
  return 0;
}
