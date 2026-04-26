// Statically dispatched IDL generator for the Bazel build of CycloneDDS.
//
// Upstream CycloneDDS 11.0 split the C backend into a separately built shared
// library (libcycloneddsidlc.so) loaded via dlopen at runtime. That makes the
// idlc binary depend on a co-located .so, which is fragile in Bazel runfiles.
//
// This replacement implements the same `idlc_load_generator` /
// `idlc_unload_generator` ABI but resolves `lang == "c"` directly to the
// libidlc generator entry points statically linked into the idlc binary. Other
// languages (e.g. python) are not supported.

#include <string.h>

#include "idlc/generator.h"
#include "idl/string.h"

extern int generate(const idl_pstate_t *pstate,
                    const idlc_generator_config_t *config);
extern const idlc_option_t **generator_options(void);

int idlc_load_generator(idlc_generator_plugin_t *plugin, const char *lang)
{
  if (lang == NULL || idl_strcasecmp(lang, "c") != 0)
    return -1;
  plugin->handle = NULL;
  plugin->generator_options = &generator_options;
  plugin->generator_annotations = NULL;
  plugin->generate = &generate;
  return 0;
}

void idlc_unload_generator(idlc_generator_plugin_t *plugin)
{
  if (!plugin)
    return;
  plugin->handle = NULL;
  plugin->generator_options = NULL;
  plugin->generator_annotations = NULL;
  plugin->generate = NULL;
}
