/**
 * @file stdout_to_file.cc
 * @brief Process wrapper that redirects a command's stdout to a file.
 *
 * Usage: stdout_to_file <output_file> -- <command> [args...]
 *
 * This avoids the need for shell redirection ("> file") in Bazel actions,
 * allowing ctx.actions.run() instead of ctx.actions.run_shell().
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#include <process.h>
#else
#include <sys/wait.h>
#include <unistd.h>
#endif

/**
 * @brief Runs argv[3..] and writes its stdout to the file at argv[1].
 * @param argc Argument count (must be >= 4).
 * @param argv Arguments: <output> -- <command> [args...]
 * @return Exit code of the child process, or 1 on failure.
 */
int main(int argc, char *argv[]) {
  if (argc < 4) {
    fprintf(stderr, "usage: %s <output> -- <command> [args...]\n", argv[0]);
    return 1;
  }
  const char *output_path = argv[1];
  if (strcmp(argv[2], "--") != 0) {
    fprintf(stderr, "expected '--' separator after output path\n");
    return 1;
  }

#ifdef _WIN32
  int out_fd = _open(output_path, _O_WRONLY | _O_CREAT | _O_TRUNC, 0644);
  if (out_fd < 0) {
    perror(output_path);
    return 1;
  }
  int saved_stdout = _dup(1);
  _dup2(out_fd, 1);
  _close(out_fd);
  intptr_t ret = _spawnvp(_P_WAIT, argv[3], &argv[3]);
  _dup2(saved_stdout, 1);
  _close(saved_stdout);
  if (ret < 0) {
    perror(argv[3]);
    return 1;
  }
  return static_cast<int>(ret);
#else
  FILE *out = fopen(output_path, "w");
  if (!out) {
    perror(output_path);
    return 1;
  }
  int fd = fileno(out);
  pid_t pid = fork();
  if (pid < 0) {
    perror("fork");
    fclose(out);
    return 1;
  }
  if (pid == 0) {
    dup2(fd, STDOUT_FILENO);
    fclose(out);
    execvp(argv[3], &argv[3]);
    perror(argv[3]);
    _exit(127);
  }
  fclose(out);
  int status;
  waitpid(pid, &status, 0);
  if (WIFEXITED(status)) return WEXITSTATUS(status);
  return 1;
#endif
}
