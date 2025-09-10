#include <stdio.h>
#include <string.h>

#include "quickjs.h"
#include "quickjs-libc.h"

int main(int argc, char **argv) {
  JSRuntime *rt = JS_NewRuntime();
  if (!rt) {
    fprintf(stderr, "Cannot create QuickJS runtime\n");
    return 1;
  }

  JSContext *ctx = JS_NewContext(rt);
  if (!ctx) {
    fprintf(stderr, "Cannot create QuickJS context\n");
    JS_FreeRuntime(rt);
    return 1;
  }
  js_std_add_helpers(ctx, argc, argv);

  const char *js_code = " \
        console.log('Hello from QuickJS!'); \
        let a = 10; \
        let b = 20; \
        console.log('a + b =', a + b); \
    ";

  JSValue result = JS_Eval(ctx, js_code, strlen(js_code), "<eval>", JS_EVAL_TYPE_GLOBAL);

  if (JS_IsException(result)) {
    fprintf(stderr, "JavaScript execution error:\n");
    js_std_dump_error(ctx);
  }

  JS_FreeValue(ctx, result);

  JS_FreeContext(ctx);
  JS_FreeRuntime(rt);

  return 0;
}
