/*
  Real, unprefixed POSIX entry points forwarding to TRE.

  Design precedent: MSYS2's libsystre (mingw-w64-libsystre 1.0.2,
  github.com/msys2/MINGW-packages/tree/master/mingw-w64-libsystre), which pairs
  a bare regex.h over <tre/tre.h> with a set of one-line forwarders. Sourcing
  regex_t from TRE rather than from the platform is what removes the need for
  the absolute-header-path substitution and the storage-field probe that TRE's
  own --enable-system-abi mode requires (configure.ac:132-258). Its post-install
  aliasing of the built archive to libgnurx.a and libregex.a, which exists so
  autoconf -lgnurx probes succeed, has no analogue here: Bazel resolves this
  library by label and has no -l search path to satisfy.

  HAZARD: on glibc, musl and Apple libc these four names are also defined by
  libc. A strong definition in the program wins at dynamic link, so pulling
  this target into a link replaces regex for the whole process, including for
  libraries that never asked for TRE. That is the point where the platform has
  no regex at all, and a deliberate, global decision everywhere else.
*/

#include <regex.h>

int
regcomp(regex_t *preg, const char *regex, int cflags)
{
  return tre_regcomp(preg, regex, cflags);
}

int
regexec(const regex_t *preg, const char *string, size_t nmatch,
        regmatch_t pmatch[], int eflags)
{
  return tre_regexec(preg, string, nmatch, pmatch, eflags);
}

size_t
regerror(int errcode, const regex_t *preg, char *errbuf, size_t errbuf_size)
{
  return tre_regerror(errcode, preg, errbuf, errbuf_size);
}

void
regfree(regex_t *preg)
{
  tre_regfree(preg);
}
