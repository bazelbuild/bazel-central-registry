/* dm_get_library_version() reports the DM_LIB_VERSION configure derived from
   VERSION_DM ("1.02.217 (2026-09-30)" for this release).  */

#include <stdio.h>
#include <string.h>

#include <libdevmapper.h>

int
main (void)
{
  char version[64];

  if (!dm_get_library_version (version, sizeof version))
    {
      fprintf (stderr, "dm_get_library_version failed\n");
      return 1;
    }
  if (strcmp (version, "1.02.217 (2026-09-30)") != 0)
    {
      fprintf (stderr, "unexpected library version: %s\n", version);
      return 1;
    }
  return 0;
}
