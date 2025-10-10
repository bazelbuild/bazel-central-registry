/* Stub fallback for bootstrap build */

#include <curses.priv.h>

NCURSES_EXPORT(const TERMTYPE2 *)
_nc_fallback2(const char *name GCC_UNUSED) {
  /* the fallback list is empty */
  return ((const TERMTYPE2 *)0);
}

#if NCURSES_EXT_NUMBERS
#undef _nc_fallback

/*
 * This entrypoint is used by tack 1.07
 */
NCURSES_EXPORT(const TERMTYPE *)
_nc_fallback(const char *name) {
  const TERMTYPE2 *tp = _nc_fallback2(name);
  const TERMTYPE *result = 0;
  if (tp != 0) {
    static TERMTYPE temp;
    _nc_export_termtype2(&temp, tp);
    result = &temp;
  }
  return result;
}
#endif
