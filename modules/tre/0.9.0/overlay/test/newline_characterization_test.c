/*
  doc/tre-api.html:96-107 lists four behaviours REG_NEWLINE must produce. TRE
  implements three; the non-matching-list clause at :98-99 is unimplemented,
  because tre_parse_bracket() (lib/tre-parse.c:422-580) never consults
  ctx->cflags while the any-character arm at :1548 does. All four are asserted
  so a failure localizes, and each asserts the behaviour TRE has rather than
  the behaviour POSIX asks for.
*/

#include <stdio.h>

#include <tre/tre.h>

static const char kSubject[] = "a\nb";

static int matches(const char *pattern, regmatch_t *pmatch) {
  regex_t preg;
  int matched;

  if (tre_regcomp(&preg, pattern, REG_EXTENDED | REG_NEWLINE) != REG_OK) {
    fprintf(stderr, "FAIL: tre_regcomp rejected %s under REG_EXTENDED|REG_NEWLINE\n", pattern);
    return -1;
  }
  matched = tre_regexec(&preg, kSubject, 1, pmatch, 0) == REG_OK;
  tre_regfree(&preg);
  return matched;
}

int main(void) {
  regmatch_t pmatch[1];
  int bracket = matches("a[^x]b", pmatch);
  int dot;
  int anchor;
  int dollar;

  if (bracket < 0) {
    return 1;
  }
  if (!bracket) {
    fputs("FAIL: a[^x]b no longer matches \"a\\nb\" under REG_NEWLINE. TRE now agrees with\n"
          "      POSIX and doc/tre-api.html:98-99; drop this expectation\n",
          stderr);
    return 1;
  }

  dot = matches("a.b", pmatch);
  if (dot < 0) {
    return 1;
  }
  if (dot) {
    fputs("FAIL: a.b matched \"a\\nb\" under REG_NEWLINE; the any-character arm regressed\n",
          stderr);
    return 1;
  }

  anchor = matches("^b", pmatch);
  if (anchor < 0) {
    return 1;
  }
  if (!anchor) {
    fputs("FAIL: ^b did not match \"a\\nb\" under REG_NEWLINE; the anchor arm regressed\n", stderr);
    return 1;
  }
  if (pmatch[0].rm_so != 2 || pmatch[0].rm_eo != 3) {
    fprintf(stderr, "FAIL: ^b should match \"a\\nb\" at [2,3) under REG_NEWLINE, got [%d,%d)\n",
            (int)pmatch[0].rm_so, (int)pmatch[0].rm_eo);
    return 1;
  }

  dollar = matches("a$", pmatch);
  if (dollar < 0) {
    return 1;
  }
  if (!dollar) {
    fputs("FAIL: a$ did not match \"a\\nb\" under REG_NEWLINE; the end-of-line arm regressed\n",
          stderr);
    return 1;
  }
  if (pmatch[0].rm_so != 0 || pmatch[0].rm_eo != 1) {
    fprintf(stderr, "FAIL: a$ should match \"a\\nb\" at [0,1) under REG_NEWLINE, got [%d,%d)\n",
            (int)pmatch[0].rm_so, (int)pmatch[0].rm_eo);
    return 1;
  }

  printf("REG_NEWLINE characterized: a[^x]b matches (POSIX says it must not), a.b does not,\n"
         "^b matches at [2,3), a$ matches at [0,1)\n");
  return 0;
}
