#include <stdio.h>
#include <string.h>

#include <linebreak.h>
#include <unibreakbase.h>
#include <wordbreak.h>

int
main (void)
{
  const char *text = "Hello world\n";
  size_t len = strlen (text);
  char brks[16];
  size_t i;

  if (unibreak_version != UNIBREAK_VERSION)
    {
      fprintf (stderr, "unexpected unibreak_version: %x\n", unibreak_version);
      return 1;
    }

  init_linebreak ();
  set_linebreaks_utf8 ((const utf8_t *) text, len, "en", brks);

  /* A break opportunity is allowed only after the space (index 5); the end
   * of text (index 10) is a mandatory break. */
  for (i = 0; i + 1 < len; ++i)
    {
      char expected = (i == 5) ? LINEBREAK_ALLOWBREAK : LINEBREAK_NOBREAK;
      if (brks[i] != expected)
        {
          fprintf (stderr, "unexpected line break %d at index %zu\n",
                   brks[i], i);
          return 1;
        }
    }
  if (brks[len - 1] != LINEBREAK_MUSTBREAK)
    {
      fprintf (stderr, "no mandatory break at end of text\n");
      return 1;
    }

  init_wordbreak ();
  set_wordbreaks_utf8 ((const utf8_t *) text, len, "en", brks);

  /* Word breaks are allowed around the space: after "Hello" (index 4) and
   * after the space (index 5). */
  if (brks[4] != WORDBREAK_BREAK || brks[5] != WORDBREAK_BREAK
      || brks[0] != WORDBREAK_NOBREAK)
    {
      fprintf (stderr, "unexpected word breaks: %d %d %d\n",
               brks[0], brks[4], brks[5]);
      return 1;
    }

  printf ("libunibreak %x smoke test passed\n", unibreak_version);
  return 0;
}
