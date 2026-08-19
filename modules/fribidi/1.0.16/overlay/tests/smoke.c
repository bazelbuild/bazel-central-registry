#include <stdio.h>
#include <string.h>

#include <fribidi.h>

int
main (void)
{
  /* Hebrew letters alef, bet, gimel in logical order. */
  FriBidiChar logical[3] = { 0x05D0, 0x05D1, 0x05D2 };
  FriBidiChar visual[3] = { 0, 0, 0 };
  FriBidiParType base = FRIBIDI_PAR_ON;
  FriBidiLevel levels;

  if (fribidi_version_info == NULL
      || strstr (fribidi_version_info, FRIBIDI_VERSION) == NULL)
    {
      fprintf (stderr, "unexpected fribidi_version_info\n");
      return 1;
    }

  levels = fribidi_log2vis (logical, 3, &base, visual, NULL, NULL, NULL);
  if (levels == 0)
    {
      fprintf (stderr, "fribidi_log2vis failed\n");
      return 1;
    }

  if (!FRIBIDI_IS_RTL (base))
    {
      fprintf (stderr, "paragraph direction not detected as RTL\n");
      return 1;
    }

  /* An RTL run must come out reversed in visual order. */
  if (visual[0] != 0x05D2 || visual[1] != 0x05D1 || visual[2] != 0x05D0)
    {
      fprintf (stderr, "unexpected visual reordering\n");
      return 1;
    }

  printf ("fribidi " FRIBIDI_VERSION " smoke test passed\n");
  return 0;
}
