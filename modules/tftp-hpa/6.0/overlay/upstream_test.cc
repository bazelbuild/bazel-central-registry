// Runs the upstream tests/test-tftp.sh client/server transfer suite.
//
// The script is used exactly as shipped; this wrapper only arranges the
// environment it expects:
//
//   * it resolves the script and both binaries out of the runfiles tree;
//   * it picks a free block of UDP ports on loopback, because the script's
//     defaults (6969 and 60969:60999) are easy to collide with;
//   * it interposes a shim in front of tftpd that prepends `-u <current
//     user>`. tftpd drops privileges to `nobody` by default, which cannot read
//     the mode 0700 directory the script serves from;
//   * it trims the block/window size matrix, whose defaults transfer a 34 MB
//     file 384 times. Every value is still overridable with --test_env.
//
// Usage: upstream_test <rlocationpath-of-script> <rlocationpath-of-tftpd>
//                      <rlocationpath-of-tftp>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <pwd.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <memory>
#include <string>
#include <vector>

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

namespace {

// Number of consecutive ports the script needs: one for the tftpd listener
// plus the --port-range it hands out data connections from.
constexpr int port_range_size = 32;
constexpr int port_block_size = port_range_size + 1;

// Returns true if every port in [base, base + count) can be bound on
// loopback. All of them are released again before returning.
bool try_bind_block(int base, int count) {
  std::vector<int> fds;
  bool ok = true;

  for (int i = 0; i < count; ++i) {
    const int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0) {
      ok = false;
      break;
    }

    struct sockaddr_in addr = {};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = htons(static_cast<uint16_t>(base + i));

    if (bind(fd, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) !=
        0) {
      close(fd);
      ok = false;
      break;
    }

    fds.push_back(fd);
  }

  for (const int fd : fds) {
    close(fd);
  }

  return ok;
}

// Finds a free block of `count` consecutive ports below the ephemeral range.
// Returns 0 when no block could be found.
int find_free_port_block(int count) {
  srand(static_cast<unsigned int>(getpid()) ^
        static_cast<unsigned int>(time(nullptr)));

  for (int attempt = 0; attempt < 64; ++attempt) {
    const int base = 20000 + (rand() % 10000);
    if (try_bind_block(base, count)) {
      return base;
    }
  }

  return 0;
}

// Writes an executable /bin/sh script to `path`.
bool write_script(const std::string& path, const std::string& body) {
  FILE* file = fopen(path.c_str(), "w");
  if (file == nullptr) {
    return false;
  }

  fputs("#!/bin/sh\n", file);
  fputs(body.c_str(), file);

  if (fclose(file) != 0) {
    return false;
  }

  return chmod(path.c_str(), 0755) == 0;
}

std::string rlocation(Runfiles* runfiles, const std::string& path) {
  const std::string resolved = runfiles->Rlocation(path);
  if (resolved.empty()) {
    fprintf(stderr, "Failed to locate runfile: %s\n", path.c_str());
  }
  return resolved;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 4) {
    fprintf(stderr, "Usage: %s <script> <tftpd> <tftp>\n", argv[0]);
    return 2;
  }

  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  if (runfiles == nullptr) {
    fprintf(stderr, "Failed to initialize runfiles: %s\n", error.c_str());
    return 1;
  }

  const std::string script = rlocation(runfiles.get(), argv[1]);
  const std::string tftpd = rlocation(runfiles.get(), argv[2]);
  const std::string tftp = rlocation(runfiles.get(), argv[3]);
  if (script.empty() || tftpd.empty() || tftp.empty()) {
    return 1;
  }

  const struct passwd* pw = getpwuid(getuid());
  if (pw == nullptr || pw->pw_name == nullptr) {
    fprintf(stderr, "No passwd entry for uid %u; tftpd -u would fail\n",
            static_cast<unsigned int>(getuid()));
    return 1;
  }

  const char* tmpdir = getenv("TEST_TMPDIR");
  if (tmpdir == nullptr) {
    tmpdir = "/tmp";
  }

  const std::string shim = std::string(tmpdir) + "/tftpd-shim";
  if (!write_script(shim, "exec \"" + tftpd + "\" -u \"" +
                              std::string(pw->pw_name) + "\" \"$@\"\n")) {
    fprintf(stderr, "Failed to write %s\n", shim.c_str());
    return 1;
  }

  const int base = find_free_port_block(port_block_size);
  if (base == 0) {
    fprintf(stderr, "Failed to find %d free consecutive UDP ports\n",
            port_block_size);
    return 1;
  }

  const std::string port = std::to_string(base);
  const std::string port_range =
      std::to_string(base + 1) + ":" + std::to_string(base + port_range_size);

  // ::1 is not reachable in every container, and the full default matrix takes
  // several minutes. `0` leaves any value supplied via --test_env alone.
  setenv("LOCALHOSTS", "127.0.0.1", 0);
  setenv("TFTP_TEST_BLKSIZES", "512 1468", 0);
  setenv("TFTP_TEST_WINSIZES", "1 64", 0);

  // The script is bash-specific, so invoke bash rather than relying on the
  // executable bit surviving into the runfiles tree.
  const char* args[] = {
      "bash",
      script.c_str(),
      shim.c_str(),
      tftp.c_str(),
      port.c_str(),
      port_range.c_str(),
      nullptr,
  };

  execvp(args[0], const_cast<char* const*>(args));

  perror("execvp(bash)");
  return 1;
}
