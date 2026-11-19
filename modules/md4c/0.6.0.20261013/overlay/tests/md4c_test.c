/* Render a small Markdown document to HTML and check the result. */

#include <stdio.h>
#include <string.h>

#include <md4c-html.h>
#include <md4c.h>

static char out[1024];
static size_t out_len = 0;

static void append(const MD_CHAR* text, MD_SIZE size, void* userdata) {
  (void)userdata;
  if (out_len + size < sizeof(out)) {
    memcpy(out + out_len, text, size);
    out_len += size;
    out[out_len] = '\0';
  }
}

int main(void) {
  const char* md = "# Title\n\nSome *emphasis* and `code`.\n";
  if (md_html(md, (MD_SIZE)strlen(md), append, NULL, MD_DIALECT_GITHUB, 0) != 0) return 1;
  printf("%s", out);
  return (strstr(out, "<h1>Title</h1>") && strstr(out, "<em>emphasis</em>") &&
          strstr(out, "<code>code</code>"))
             ? 0
             : 1;
}
