#include <backtrace.h>
#include <stdint.h>
#include <stdio.h>

struct callback_state {
  int full_called;
  int syminfo_called;
};

static void error_callback(void *data, const char *message, int error_number) {
  (void)data;
  (void)message;
  (void)error_number;
}

static int full_callback(void *data, uintptr_t pc, const char *filename,
                         int line_number, const char *function) {
  struct callback_state *state = data;
  (void)pc;
  (void)filename;
  (void)line_number;
  (void)function;
  state->full_called = 1;
  return 0;
}

static void syminfo_callback(void *data, uintptr_t pc, const char *symbol_name,
                             uintptr_t symbol_value, uintptr_t symbol_size) {
  struct callback_state *state = data;
  (void)pc;
  (void)symbol_name;
  (void)symbol_value;
  (void)symbol_size;
  state->syminfo_called = 1;
}

int main(int argc, char **argv) {
  struct callback_state callbacks = {0, 0};
  int pcinfo_result;
  int syminfo_result;
  struct backtrace_state *state = backtrace_create_state(
      argc > 0 ? argv[0] : 0, 1, error_callback, &callbacks);

  if (state == 0) {
    return 1;
  }

  pcinfo_result = backtrace_pcinfo(state, (uintptr_t)&main, full_callback,
                                  error_callback, &callbacks);
  syminfo_result = backtrace_syminfo(state, (uintptr_t)&main, syminfo_callback,
                                     error_callback, &callbacks);
  if (!syminfo_result || !callbacks.full_called || !callbacks.syminfo_called) {
    fprintf(stderr, "pcinfo=%d full=%d syminfo=%d symbol=%d\n", pcinfo_result,
            callbacks.full_called, syminfo_result, callbacks.syminfo_called);
    return 1;
  }

  return 0;
}
