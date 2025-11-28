/* Python buildinfo implemented using Bazel linkstamps. */

#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

/* These are defined in bazel_linkstamp.cc. */
extern const char _bazel_embed_label[];
extern const long long _bazel_build_timestamp;
extern const char _bazel_username[];
extern const char _bazel_scm_revision[];
extern const char _bazel_scm_status[];

const char *
_Py_gitversion(void)
{
    return _bazel_scm_revision;
}

const char *
_Py_gitidentifier(void)
{
    return "rSERVER";
}

static pthread_once_t buildinfo_inited = PTHREAD_ONCE_INIT;
static char buildinfo[256];

static void
compute_buildinfo(void)
{
    char pretty_build_time[25] = "redacted";
    if (_bazel_build_timestamp) {
        time_t build_time_t = _bazel_build_timestamp;
        struct tm build_time;
        gmtime_r(&build_time_t, &build_time);
        strftime(pretty_build_time, sizeof(pretty_build_time), "%Y_%m_%d, %H:%M:%SZ", &build_time);
    }
    const char *scm_status = _bazel_scm_status, *maybe_space = " ";
    if (strlen(scm_status) == 0 || strcmp(scm_status, "Clean") == 0) {
      scm_status = maybe_space = "";
    }
    snprintf(buildinfo, sizeof(buildinfo), "%s%s%s@%s, %s", scm_status, maybe_space, _Py_gitidentifier(), _Py_gitversion(), pretty_build_time);
}

const char *
Py_GetBuildInfo(void)
{
    pthread_once(&buildinfo_inited, compute_buildinfo);
    return buildinfo;
}
