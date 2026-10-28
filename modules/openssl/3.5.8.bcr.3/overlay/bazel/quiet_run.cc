// Tiny build tool: runs a command and shows its stdout/stderr only if it
// fails. Used for actions whose tools chatter on stderr while succeeding
// (OpenSSL's perlasm compiler probes), since consumers cannot silence
// action output themselves.
// Usage: quiet_run <executable> [args...]

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#include <process.h>
#else
#include <sys/wait.h>
#include <unistd.h>
#endif

namespace {

// Reads everything from fd until EOF.
std::string drain(int fd) {
    std::string out;
    char buf[65536];
    for (;;) {
#ifdef _WIN32
        int n = _read(fd, buf, sizeof(buf));
#else
        ssize_t n = read(fd, buf, sizeof(buf));
#endif
        if (n <= 0) break;
        out.append(buf, static_cast<size_t>(n));
    }
    return out;
}

}  // namespace

int main(int argc, char* argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <executable> [args...]\n", argv[0]);
        return 1;
    }
    char** child_argv = argv + 1;

#ifdef _WIN32
    // cmd.exe misparses forward slashes in .bat paths as option flags.
    std::string executable = child_argv[0];
    for (char& c : executable) {
        if (c == '/') c = '\\';
    }
    child_argv[0] = &executable[0];

    int fds[2];
    if (_pipe(fds, 65536, _O_BINARY) != 0) {
        perror("_pipe");
        return 1;
    }
    int saved_stdout = _dup(1);
    int saved_stderr = _dup(2);
    _dup2(fds[1], 1);
    _dup2(fds[1], 2);
    intptr_t pid = _spawnvp(_P_NOWAIT, child_argv[0],
                            const_cast<const char* const*>(child_argv));
    int spawn_errno = errno;
    _dup2(saved_stdout, 1);
    _dup2(saved_stderr, 2);
    _close(saved_stdout);
    _close(saved_stderr);
    _close(fds[1]);
    if (pid == -1) {
        fprintf(stderr, "quiet_run: %s: %s\n", child_argv[0],
                strerror(spawn_errno));
        return 1;
    }
    std::string output = drain(fds[0]);
    _close(fds[0]);
    int status = 0;
    if (_cwait(&status, pid, 0) == -1) {
        perror("_cwait");
        return 1;
    }
    int exit_code = status;
#else
    int fds[2];
    if (pipe(fds) != 0) {
        perror("pipe");
        return 1;
    }
    pid_t pid = fork();
    if (pid == -1) {
        perror("fork");
        return 1;
    }
    if (pid == 0) {
        close(fds[0]);
        dup2(fds[1], 1);
        dup2(fds[1], 2);
        close(fds[1]);
        execvp(child_argv[0], child_argv);
        perror(child_argv[0]);
        _exit(127);
    }
    close(fds[1]);
    std::string output = drain(fds[0]);
    close(fds[0]);
    int status = 0;
    if (waitpid(pid, &status, 0) == -1) {
        perror("waitpid");
        return 1;
    }
    int exit_code =
        WIFEXITED(status) ? WEXITSTATUS(status) : 128 + WTERMSIG(status);
#endif

    if (exit_code != 0) {
        fwrite(output.data(), 1, output.size(), stderr);
        fflush(stderr);
    }
    return exit_code;
}
