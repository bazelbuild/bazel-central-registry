// Tiny build tool: runs a command with stdout redirected to a file.
// Usage: redirect_stdout <executable> <output> -- [args...]

#include <cstdio>
#include <cstdlib>
#include <cstring>

#ifdef _WIN32
#include <process.h>
#include <string.h>

// cmd.exe misparses forward slashes in .bat paths as option flags.
static char* to_backslashes(const char* path) {
    char* copy = _strdup(path);
    if (copy) {
        for (char* p = copy; *p; ++p) {
            if (*p == '/') *p = '\\';
        }
    }
    return copy;
}
#else
#include <unistd.h>
#endif

int main(int argc, char* argv[]) {
    if (argc < 4) {
        fprintf(stderr, "Usage: %s <executable> <output> -- [args...]\n",
                argv[0]);
        return 1;
    }

    const char* executable = argv[1];
    const char* output = argv[2];

    if (strcmp(argv[3], "--") != 0) {
        fprintf(stderr, "Expected '--' as third argument, got '%s'\n", argv[3]);
        return 1;
    }

    if (!freopen(output, "w", stdout)) {
        perror("freopen");
        return 1;
    }

    int forwarded_argc = argc - 4;
    char** child_argv =
        static_cast<char**>(malloc(sizeof(char*) * (forwarded_argc + 2)));
    child_argv[0] = argv[1];
    for (int i = 0; i < forwarded_argc; i++) {
        child_argv[i + 1] = argv[4 + i];
    }
    child_argv[forwarded_argc + 1] = nullptr;

#ifdef _WIN32
    char* win_executable = to_backslashes(executable);
    if (!win_executable) {
        perror("_strdup");
        free(child_argv);
        return 1;
    }
    child_argv[0] = win_executable;
    int status = _spawnvp(_P_WAIT, win_executable,
                          const_cast<const char* const*>(child_argv));
    free(win_executable);
    free(child_argv);
    if (status == -1) {
        perror("_spawnvp");
        return 1;
    }
    return status;
#else
    execvp(executable, child_argv);
    perror("execvp");
    free(child_argv);
    return 1;
#endif
}
