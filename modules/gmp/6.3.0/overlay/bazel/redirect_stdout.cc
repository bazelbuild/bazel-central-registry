// Runs a tool binary and redirects its stdout to a file.
// Usage: redirect_stdout <output_file> <tool> [args...]
//
// This wrapper exists because GMP's gen-* programs write generated
// headers/sources to stdout. Bazel's ctx.actions.run does not support
// stdout capture, so this wrapper bridges the gap.

#include <cstdio>
#include <cstdlib>

#ifdef _WIN32
#include <process.h>
#else
#include <sys/wait.h>
#include <unistd.h>
#endif

int main(int argc, char* argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <output> <tool> [args...]\n", argv[0]);
        return 1;
    }

    const char* output = argv[1];

    if (!freopen(output, "w", stdout)) {
        fprintf(stderr, "redirect_stdout: failed to open %s for writing\n",
                output);
        return 1;
    }

#ifdef _WIN32
    int rc = _spawnvp(_P_WAIT, argv[2], &argv[2]);
    return rc;
#else
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }
    if (pid == 0) {
        execvp(argv[2], &argv[2]);
        perror("execvp");
        _exit(127);
    }
    int status;
    waitpid(pid, &status, 0);
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    return 1;
#endif
}
