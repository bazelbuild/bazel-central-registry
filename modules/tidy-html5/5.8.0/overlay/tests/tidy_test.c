/* Clean a malformed HTML snippet and check the repaired output. */

#include <stdio.h>
#include <string.h>

#include <tidy.h>
#include <tidybuffio.h>

int main(void) {
  printf("libtidy %s (%s)\n", tidyLibraryVersion(), tidyReleaseDate());
  TidyDoc doc = tidyCreate();
  TidyBuffer out = {0};
  TidyBuffer errors = {0};
  tidyOptSetBool(doc, TidyXhtmlOut, yes);
  tidyOptSetInt(doc, TidyBodyOnly, TidyYesState);
  tidySetErrorBuffer(doc, &errors);
  int rc = tidyParseString(doc, "<p>Hello <b>world");
  if (rc >= 0) rc = tidyCleanAndRepair(doc);
  if (rc >= 0) rc = tidySaveBuffer(doc, &out);
  int ok = rc >= 0 && out.bp != NULL && strstr((const char*)out.bp, "<b>world</b>") != NULL;
  if (out.bp) printf("%s", (const char*)out.bp);
  tidyBufFree(&out);
  tidyBufFree(&errors);
  tidyRelease(doc);
  return ok && strcmp(tidyLibraryVersion(), "5.8.0") == 0 ? 0 : 1;
}
