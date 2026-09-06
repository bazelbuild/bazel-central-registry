#include <libestr.h>
#include <string.h>

int main()
{
  return strcmp(es_version(), "0.1.11") == 0 ? 0 : 1;
}
