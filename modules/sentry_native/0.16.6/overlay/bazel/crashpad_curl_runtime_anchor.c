#include <curl/curl.h>

char *(*volatile sentry_crashpad_force_curl_version)(void) = curl_version;
