#include <ares.h>
#include <errno.h>
#include <linux/filter.h>
#include <linux/seccomp.h>
#include <stddef.h>
#include <stdio.h>
#include <sys/inotify.h>
#include <sys/prctl.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <unistd.h>

enum { REGRESSION_FAILURE = 1, SETUP_FAILURE = 2 };

static int deny_syscall(int syscall_number) {
  struct sock_filter filter[] = {
      BPF_STMT(BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, nr)),
      BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, syscall_number, 0, 1),
      BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ERRNO | EPERM),
      BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),
  };
  struct sock_fprog program = {
      .len = sizeof(filter) / sizeof(filter[0]),
      .filter = filter,
  };

  if (prctl(PR_SET_NO_NEW_PRIVS, 1L, 0L, 0L, 0L) != 0) {
    perror("setup: PR_SET_NO_NEW_PRIVS");
    return SETUP_FAILURE;
  }
  if (prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &program, 0L, 0L) != 0) {
    perror("setup: PR_SET_SECCOMP");
    return SETUP_FAILURE;
  }
  return 0;
}

static int verify_watch_failure(int syscall_number, const char* name) {
  int fd = -1;
  if (syscall_number == SYS_inotify_add_watch) {
    fd = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
    if (fd < 0) {
      perror("setup: inotify_init1 before denied watch");
      return SETUP_FAILURE;
    }
  }

  errno = 0;
  int result = syscall_number == SYS_inotify_init1 ? inotify_init1(IN_NONBLOCK | IN_CLOEXEC)
                                                   : inotify_add_watch(fd, "/etc", IN_MODIFY);
  int saved_errno = errno;
  if (fd >= 0) {
    close(fd);
  }
  if (syscall_number == SYS_inotify_init1 && result >= 0) {
    close(result);
  }
  if (result != -1 || saved_errno != EPERM) {
    fprintf(stderr, "setup: %s returned %d with errno %d; expected -1 with EPERM\n", name, result,
            saved_errno);
    return SETUP_FAILURE;
  }
  return 0;
}

static int check_channel(void) {
  int status = ares_library_init(ARES_LIB_INIT_ALL);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "setup: c-ares initialization: %s\n", ares_strerror(status));
    return SETUP_FAILURE;
  }
  if (!ares_threadsafety()) {
    fputs("setup: c-ares was built without thread support\n", stderr);
    ares_library_cleanup();
    return SETUP_FAILURE;
  }

  struct ares_options options = {0};
  ares_channel_t* channel = NULL;
  options.resolvconf_path = "/dev/null";
  options.evsys = ARES_EVSYS_DEFAULT;
  status = ares_init_options(&channel, &options, ARES_OPT_RESOLVCONF | ARES_OPT_EVENT_THREAD);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "regression: channel initialization after watcher failure: %s\n",
            ares_strerror(status));
    ares_library_cleanup();
    return REGRESSION_FAILURE;
  }

  status = ares_reinit(channel);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "regression: channel reinitialization: %s\n", ares_strerror(status));
    ares_destroy(channel);
    ares_library_cleanup();
    return REGRESSION_FAILURE;
  }

  status = ares_queue_wait_empty(channel, 1000);
  ares_destroy(channel);
  ares_library_cleanup();
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "regression: empty channel queue: %s\n", ares_strerror(status));
    return REGRESSION_FAILURE;
  }
  return 0;
}

static int check_watch_failure(int syscall_number, const char* name) {
  pid_t child = fork();
  if (child < 0) {
    perror("setup: fork");
    return SETUP_FAILURE;
  }
  if (child == 0) {
    int result = deny_syscall(syscall_number);
    if (result == 0) {
      result = verify_watch_failure(syscall_number, name);
    }
    if (result == 0) {
      result = check_channel();
    }
    _exit(result);
  }

  int status;
  while (waitpid(child, &status, 0) < 0) {
    if (errno != EINTR) {
      perror("setup: waitpid");
      return SETUP_FAILURE;
    }
  }
  if (!WIFEXITED(status)) {
    fprintf(stderr, "setup: %s child did not exit normally (wait status %d)\n", name, status);
    return SETUP_FAILURE;
  }
  int result = WEXITSTATUS(status);
  if (result != 0) {
    fprintf(stderr, "%s: %s failed\n", name,
            result == SETUP_FAILURE ? "setup" : "channel lifecycle");
    return result;
  }
  printf("%s: denied with EPERM; channel lifecycle passed\n", name);
  return 0;
}

int main(void) {
  int init_result = check_watch_failure(SYS_inotify_init1, "inotify_init1");
  int watch_result = check_watch_failure(SYS_inotify_add_watch, "inotify_add_watch");
  if (init_result == SETUP_FAILURE || watch_result == SETUP_FAILURE) {
    return SETUP_FAILURE;
  }
  return init_result || watch_result;
}
