#include <ngspice/sharedspice.h>
#include <omp.h>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

#include <unistd.h>

namespace {
bool failed = false;
std::string messages;

int Log(char* message, int, void*) {
  const std::string line(message);
  messages += line + "\n";
  if (line.find("stderr Error") != std::string::npos ||
      line.find("stderr Fatal") != std::string::npos ||
      line.find("simulation(s) aborted") != std::string::npos)
    failed = true;
  std::fprintf(stderr, "%s\n", message);
  return 0;
}

int Exit(int, NG_BOOL, NG_BOOL, int, void*) {
  failed = true;
  return 0;
}

bool Command(std::string command) {
  return ngSpice_Command(command.data()) == 0 && !failed;
}

bool ConsumerParallelRegion() {
  int threads = 0;
#pragma omp parallel num_threads(2) reduction(+ : threads)
  { threads += 1; }
  if (threads != 2) {
    std::fprintf(stderr, "Expected two consumer OpenMP threads, got %d\n", threads);
    return false;
  }
  return true;
}
}  // namespace

int main(int argc, char** argv) {
  if (argc != 2) return 1;
  const std::string init_file(argv[1]);
  const auto separator = init_file.find_last_of('/');
  const std::string init_dir = separator == std::string::npos
                                   ? "."
                                   : init_file.substr(0, separator);
  // A real local .spiceinit prevents ngspice from reading the user's home file.
  if (chdir(init_dir.c_str()) != 0 || setenv("SPICE_SCRIPTS", "", 1) != 0 ||
      setenv("SPICE_USERINIT_DIR", ".", 1) != 0)
    return 1;

  // Initialize the consumer's runtime first: a privately embedded runtime in
  // libngspice previously caused LLVM's duplicate-runtime abort during init.
  if (!ConsumerParallelRegion() ||
      ngSpice_Init(Log, nullptr, Exit, nullptr, nullptr, nullptr, nullptr) != 0 ||
      failed || !Command("version -f"))
    return 1;
  if (messages.find("OpenMP multithreading for BSIM3, BSIM4 enabled") ==
      std::string::npos) {
    std::fprintf(stderr, "This regression requires ngspice OpenMP support\n");
    return 1;
  }

  std::vector<std::string> circuit = {
      "Clang consumer and ngspice share one OpenMP runtime",
      "Vd drain 0 1.2", "Vg gate 0 0",
      ".model n nmos level=14 version=4.8.3 vth0=0.45"};
  for (int i = 0; i < 16; ++i)
    circuit.push_back("M" + std::to_string(i) + " drain gate 0 0 n W=10u L=1u");
  circuit.push_back(".end");
  std::vector<char*> lines;
  for (auto& line : circuit) lines.push_back(line.data());
  lines.push_back(nullptr);
  if (!Command("set num_threads=2") || ngSpice_Circ(lines.data()) != 0 ||
      failed || !Command("dc vg 0 1.2 0.1"))
    return 1;

  char current_name[] = "i(vd)";
  const auto* current = ngGet_Vec_Info(current_name);
  if (!current || !current->v_realdata || current->v_length != 13) {
    std::fprintf(stderr, "Missing BSIM4 DC sweep\n");
    return 1;
  }
  for (int i = 0; i < current->v_length; ++i) {
    if (!std::isfinite(current->v_realdata[i])) return 1;
  }
  if (std::abs(current->v_realdata[0]) > 1e-6 ||
      !(current->v_realdata[12] < -1e-6)) {
    std::fprintf(stderr, "BSIM4 sweep did not move from cutoff to conduction\n");
    return 1;
  }
  return ConsumerParallelRegion() ? 0 : 1;
}
