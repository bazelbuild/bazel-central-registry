#include <ares.h>
#include <stdio.h>

static int check_channel(ares_evsys_t event_system, int event_thread) {
  struct ares_options options = {0};
  ares_channel_t* channel = NULL;
  int option_mask = ARES_OPT_RESOLVCONF;

  options.resolvconf_path = "/dev/null";
  options.evsys = event_system;
  if (event_thread) {
    option_mask |= ARES_OPT_EVENT_THREAD;
  }

  int status = ares_init_options(&channel, &options, option_mask);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "event system %d, event thread %d: %s\n", event_system, event_thread,
            ares_strerror(status));
    return 1;
  }

  status = ares_reinit(channel);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "channel reinitialization: %s\n", ares_strerror(status));
    ares_destroy(channel);
    return 1;
  }

  status = ares_queue_wait_empty(channel, 1000);
  ares_destroy(channel);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "empty queue, event system %d, event thread %d: %s\n", event_system,
            event_thread, ares_strerror(status));
    return 1;
  }

  printf("event system %d, event thread %d: initialized, reinitialized, drained, destroyed\n",
         event_system, event_thread);
  return 0;
}

int main(void) {
  int status = ares_library_init(ARES_LIB_INIT_ALL);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "c-ares initialization: %s\n", ares_strerror(status));
    return 1;
  }

  if (!ares_threadsafety()) {
    fprintf(stderr, "c-ares was built without thread support\n");
    ares_library_cleanup();
    return 1;
  }

  int result = check_channel(ARES_EVSYS_DEFAULT, 0);
  const ares_evsys_t event_systems[] = {
      ARES_EVSYS_DEFAULT,
      ARES_EVSYS_EPOLL,
      ARES_EVSYS_POLL,
      ARES_EVSYS_SELECT,
  };
  for (size_t i = 0; result == 0 && i < sizeof(event_systems) / sizeof(event_systems[0]); ++i) {
    result = check_channel(event_systems[i], 1);
  }

  ares_library_cleanup();
  return result;
}
