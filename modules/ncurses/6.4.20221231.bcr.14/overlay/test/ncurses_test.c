// Checks that ncurses can be linked and used without a terminal database.

#include <curses.h>
#include <stdio.h>
#include <string.h>
#include <term.h>

int main(void) {
  const char *version = curses_version();
  if (strncmp(version, "ncurses 6.4", strlen("ncurses 6.4")) != 0) {
    fprintf(stderr, "unexpected version: %s\n", version);
    return 1;
  }

  // Formats a cursor_address capability as used by xterm.
  const char *cup = tiparm("\033[%i%p1%d;%p2%dH", 4, 9);
  if (cup == NULL || strcmp(cup, "\033[5;10H") != 0) {
    fprintf(stderr, "unexpected cursor_address: %s\n", cup ? cup + 1 : "(null)");
    return 1;
  }

  printf("PASS: %s\n", version);
  return 0;
}
