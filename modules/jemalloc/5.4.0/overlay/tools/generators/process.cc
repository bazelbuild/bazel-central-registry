#include "process.h"

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#else
#include <fcntl.h>
#include <spawn.h>
#include <sys/wait.h>

#include <cstring>
extern char** environ;
#endif

namespace process {

namespace {

#ifdef _WIN32
// One argument of a command line as CommandLineToArgvW and the C runtime split it: quoted if it is empty or holds
// whitespace or a quote, with each quote and the backslashes before it or before the closing quote escaped.
std::string quote_argument(const std::string& argument) {
    if (!argument.empty() && argument.find_first_of(" \t\n\v\"") == std::string::npos) return argument;
    std::string quoted = "\"";
    for (std::string::size_type index = 0;; ++index) {
        std::string::size_type backslashes = 0;
        while (index < argument.size() && argument[index] == '\\') {
            ++index;
            ++backslashes;
        }
        if (index == argument.size()) {
            quoted.append(backslashes * 2, '\\');
            break;
        }
        if (argument[index] == '"') {
            quoted.append(backslashes * 2 + 1, '\\');
        } else {
            quoted.append(backslashes, '\\');
        }
        quoted.push_back(argument[index]);
    }
    quoted.push_back('"');
    return quoted;
}

HANDLE create_inheritable_file(const std::string& path) {
    SECURITY_ATTRIBUTES inheritable = {sizeof(inheritable), nullptr, TRUE};
    return CreateFileA(path.c_str(), GENERIC_WRITE, FILE_SHARE_READ, &inheritable, CREATE_ALWAYS,
                       FILE_ATTRIBUTE_NORMAL, nullptr);
}
#endif

}  // namespace

bool run(const std::string& program, const std::vector<std::string>& arguments, const std::string* stdout_path,
         const std::string& stderr_path, int* exit_code, std::string* error) {
#ifdef _WIN32
    // CreateProcess finds a program by a path with backslashes; Bazel's are written with slashes.
    std::string windows_program = program;
    for (char& character : windows_program) {
        if (character == '/') character = '\\';
    }
    std::string command_line = quote_argument(windows_program);
    for (const std::string& argument : arguments) command_line += " " + quote_argument(argument);
    std::vector<char> command_line_buffer(command_line.begin(), command_line.end());
    command_line_buffer.push_back('\0');

    HANDLE child_stdout = stdout_path ? create_inheritable_file(*stdout_path) : GetStdHandle(STD_OUTPUT_HANDLE);
    HANDLE child_stderr = create_inheritable_file(stderr_path);
    if ((stdout_path && child_stdout == INVALID_HANDLE_VALUE) || child_stderr == INVALID_HANDLE_VALUE) {
        *error = "cannot create " + (stdout_path ? *stdout_path + " or " : std::string()) + stderr_path + ": error " +
                 std::to_string(GetLastError());
        if (stdout_path && child_stdout != INVALID_HANDLE_VALUE) CloseHandle(child_stdout);
        if (child_stderr != INVALID_HANDLE_VALUE) CloseHandle(child_stderr);
        return false;
    }
    STARTUPINFOA startup_info = {};
    startup_info.cb = sizeof(startup_info);
    startup_info.dwFlags = STARTF_USESTDHANDLES;
    startup_info.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    startup_info.hStdOutput = child_stdout;
    startup_info.hStdError = child_stderr;
    PROCESS_INFORMATION process_information = {};
    BOOL created = CreateProcessA(nullptr, command_line_buffer.data(), nullptr, nullptr, TRUE, 0, nullptr, nullptr,
                                  &startup_info, &process_information);
    DWORD create_error = GetLastError();
    if (stdout_path) CloseHandle(child_stdout);
    CloseHandle(child_stderr);
    if (!created) {
        *error = "cannot run " + windows_program + ": error " + std::to_string(create_error);
        return false;
    }
    WaitForSingleObject(process_information.hProcess, INFINITE);
    DWORD status = 1;
    if (!GetExitCodeProcess(process_information.hProcess, &status)) status = 1;
    CloseHandle(process_information.hThread);
    CloseHandle(process_information.hProcess);
    *exit_code = status > 255 ? 1 : static_cast<int>(status);
    return true;
#else
    std::vector<std::string> command = {program};
    command.insert(command.end(), arguments.begin(), arguments.end());
    std::vector<char*> argument_pointers;
    for (std::string& argument : command) argument_pointers.push_back(&argument[0]);
    argument_pointers.push_back(nullptr);

    posix_spawn_file_actions_t file_actions;
    int error_number = posix_spawn_file_actions_init(&file_actions);
    if (error_number != 0) {
        *error = "cannot run " + program + ": " + std::strerror(error_number);
        return false;
    }
    if (stdout_path) {
        error_number = posix_spawn_file_actions_addopen(&file_actions, 1, stdout_path->c_str(),
                                                        O_WRONLY | O_CREAT | O_TRUNC, 0644);
    }
    if (error_number == 0) {
        error_number = posix_spawn_file_actions_addopen(&file_actions, 2, stderr_path.c_str(),
                                                        O_WRONLY | O_CREAT | O_TRUNC, 0644);
    }
    pid_t pid;
    if (error_number == 0) {
        error_number = posix_spawnp(&pid, program.c_str(), &file_actions, nullptr, argument_pointers.data(), environ);
    }
    posix_spawn_file_actions_destroy(&file_actions);
    if (error_number != 0) {
        *error = "cannot run " + program + ": " + std::strerror(error_number);
        return false;
    }
    int wait_status;
    if (waitpid(pid, &wait_status, 0) < 0) {
        *error = "waiting for " + program + " failed";
        return false;
    }
    *exit_code = WIFEXITED(wait_status) ? WEXITSTATUS(wait_status) : 128 + WTERMSIG(wait_status);
    return true;
#endif
}

}  // namespace process
