/*
  The bare <tre/tre.h> and <tre/regex.h> spellings are the contract under test,
  not plumbing.

  TRE_VERSION comes from the generated tre-config.h this consumer compiles
  against; tre_config(TRE_CONFIG_VERSION, ...) returns the copy the library was
  compiled with, so comparing them catches a header wired against object code
  from another release.
*/

#include <stdio.h>
#include <string.h>

#include <tre/regex.h>
#include <tre/tre.h>

/* The calls below would otherwise resolve to whatever else owns these names. */
#if !defined(regcomp) || !defined(regexec) || !defined(regfree)
#error "<tre/regex.h> did not define the POSIX names onto tre_reg*"
#endif

int main(void) {
  const char *runtime_version = NULL;
  regex_t preg;
  regmatch_t pmatch[2];

  if (tre_config(TRE_CONFIG_VERSION, &runtime_version) != REG_OK) {
    fputs("FAIL: tre_config(TRE_CONFIG_VERSION) did not answer\n", stderr);
    return 1;
  }
  if (strcmp(runtime_version, TRE_VERSION) != 0) {
    fprintf(stderr, "FAIL: header TRE_VERSION is %s but the library reports %s\n",
            TRE_VERSION, runtime_version);
    return 1;
  }

  if (tre_regcomp(&preg, "f(o+)bar", REG_EXTENDED) != REG_OK) {
    fputs("FAIL: tre_regcomp rejected f(o+)bar\n", stderr);
    return 1;
  }
  if (tre_regexec(&preg, "xx fooobar xx", 2, pmatch, 0) != REG_OK) {
    fputs("FAIL: tre_regexec found no match for f(o+)bar in \"xx fooobar xx\"\n", stderr);
    tre_regfree(&preg);
    return 1;
  }
  if (pmatch[0].rm_so != 3 || pmatch[0].rm_eo != 10 || pmatch[1].rm_so != 4 ||
      pmatch[1].rm_eo != 7) {
    fprintf(stderr, "FAIL: expected whole match [3,10) and group [4,7), got [%d,%d) and [%d,%d)\n",
            (int)pmatch[0].rm_so, (int)pmatch[0].rm_eo, (int)pmatch[1].rm_so,
            (int)pmatch[1].rm_eo);
    tre_regfree(&preg);
    return 1;
  }
  tre_regfree(&preg);

  if (regcomp(&preg, "f(o+)bar", REG_EXTENDED) != REG_OK ||
      regexec(&preg, "xx fooobar xx", 2, pmatch, 0) != REG_OK || pmatch[0].rm_so != 3 ||
      pmatch[0].rm_eo != 10) {
    fputs("FAIL: the <tre/regex.h> remap did not reach tre_regcomp/tre_regexec\n", stderr);
    return 1;
  }
  regfree(&preg);

  printf("public surface OK: TRE %s, <tre/tre.h> and <tre/regex.h> both reachable\n",
         runtime_version);
  return 0;
}
