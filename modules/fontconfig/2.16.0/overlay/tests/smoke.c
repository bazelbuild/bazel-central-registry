#include <stdio.h>

#include <fontconfig/fontconfig.h>

int main(void)
{
    if (FcGetVersion() != 21600) {
        fprintf(stderr, "unexpected fontconfig version: %d\n",
                FcGetVersion());
        return 1;
    }

    /* Load a config; on hosts without /etc/fonts this exercises the
     * built-in fallback config. */
    FcConfig *config = FcInitLoadConfig();
    if (!config) {
        fprintf(stderr, "FcInitLoadConfig failed\n");
        return 1;
    }

    FcPattern *pattern = FcNameParse((const FcChar8 *) "sans-serif");
    if (!pattern) {
        fprintf(stderr, "FcNameParse failed\n");
        return 1;
    }

    FcPatternDestroy(pattern);
    FcConfigDestroy(config);
    FcFini();

    printf("fontconfig 2.16.0 smoke test passed\n");
    return 0;
}
