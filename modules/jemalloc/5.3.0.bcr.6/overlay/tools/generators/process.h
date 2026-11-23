#pragma once

#include <string>
#include <vector>

namespace process {

// Runs `program` with `arguments` and waits for it. Its stdout goes to *stdout_path, or is inherited when stdout_path
// is null, and its stderr to stderr_path; both files are created or truncated. On POSIX a program named without a
// slash is found on PATH. On Windows slashes in `program` become backslashes, as CreateProcess needs.
//
// Returns false, with *error saying why, when the program cannot be started or waited for. Otherwise sets *exit_code
// to the program's exit status: 128 plus the signal for a program a signal ended on POSIX, and 1 for an exit code above
// 255 on Windows, such as the NTSTATUS of a crash.
bool run(const std::string& program, const std::vector<std::string>& arguments, const std::string* stdout_path,
         const std::string& stderr_path, int* exit_code, std::string* error);

}  // namespace process
