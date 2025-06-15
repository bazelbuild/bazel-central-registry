#include "json.h"
#include <string.h>

int main()
{
  return strcmp(fjson_version(), "1.2304.0") == 0 ? 0 : 1;
}
