// Runs COMMAND and passes only if it exits non-zero with EXPECTED in its stderr. Every "@TEST_TMPDIR@" in an
// argument becomes $TEST_TMPDIR, for commands that must write somewhere.
//
//   expect_failure EXPECTED COMMAND [ARG]...

#include <fcntl.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>

extern char** environ;

namespace {

std::string replace_all(std::string text, const std::string& from, const std::string& to) {
    for (std::string::size_type at = text.find(from); at != std::string::npos; at = text.find(from, at + to.size())) {
        text.replace(at, from.size(), to);
    }
    return text;
}

}  // namespace

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "usage: expect_failure EXPECTED COMMAND [ARG]...\n";
        return 2;
    }
    const std::string expected = argv[1];
    const char* test_tmpdir = std::getenv("TEST_TMPDIR");
    std::vector<std::string> arguments;
    for (int index = 2; index < argc; ++index) {
        arguments.push_back(replace_all(argv[index], "@TEST_TMPDIR@", test_tmpdir ? test_tmpdir : "."));
    }
    std::vector<char*> argument_pointers;
    for (std::string& argument : arguments) argument_pointers.push_back(&argument[0]);
    argument_pointers.push_back(nullptr);

    int stderr_pipe[2];
    if (pipe(stderr_pipe) != 0) {
        std::cerr << "expect_failure: pipe: " << std::strerror(errno) << "\n";
        return 2;
    }
    posix_spawn_file_actions_t file_actions;
    posix_spawn_file_actions_init(&file_actions);
    posix_spawn_file_actions_adddup2(&file_actions, stderr_pipe[1], 2);
    posix_spawn_file_actions_addclose(&file_actions, stderr_pipe[0]);
    pid_t pid;
    int error_number = posix_spawn(&pid, argument_pointers[0], &file_actions, nullptr, argument_pointers.data(), environ);
    posix_spawn_file_actions_destroy(&file_actions);
    close(stderr_pipe[1]);
    if (error_number != 0) {
        std::cerr << "expect_failure: cannot run " << arguments[0] << ": " << std::strerror(error_number) << "\n";
        return 2;
    }
    std::string captured;
    char buffer[4096];
    for (ssize_t count; (count = read(stderr_pipe[0], buffer, sizeof buffer)) > 0;) captured.append(buffer, count);
    close(stderr_pipe[0]);
    int wait_status;
    if (waitpid(pid, &wait_status, 0) < 0) {
        std::cerr << "expect_failure: waiting for " << arguments[0] << " failed\n";
        return 2;
    }
    std::cerr << captured;

    const bool failed = !WIFEXITED(wait_status) || WEXITSTATUS(wait_status) != 0;
    if (failed && captured.find(expected) != std::string::npos) return 0;
    std::cerr << "expect_failure: wanted " << arguments[0] << " to fail mentioning \"" << expected << "\"\n";
    return 1;
}
