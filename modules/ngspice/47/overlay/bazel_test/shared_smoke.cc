#include <ngspice/sharedspice.h>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <utility>
#include <vector>

namespace {
bool simulator_exited = false;
bool simulator_error = false;
std::string messages;

int Log(char* message, int, void*) {
  const std::string line(message);
  messages += line + "\n";
  // Some ngspice failures still return status zero from ngSpice_Command.
  if (line.find("stderr Error") != std::string::npos ||
      line.find("stderr Fatal error") != std::string::npos ||
      line.find("simulation(s) aborted") != std::string::npos)
    simulator_error = true;
  std::fprintf(stderr, "%s\n", message);
  return 0;
}

int Exit(int, NG_BOOL, NG_BOOL, int, void*) {
  simulator_exited = true;
  return 0;
}

bool Command(std::string text) {
  return ngSpice_Command(&text[0]) == 0 && !simulator_exited && !simulator_error;
}

bool Circuit(std::vector<std::string> lines, const char* analysis) {
  std::vector<char*> pointers;
  for (auto& line : lines) pointers.push_back(&line[0]);
  pointers.push_back(nullptr);
  return ngSpice_Circ(pointers.data()) == 0 && Command(analysis);
}

std::vector<double> Values(std::string name) {
  const auto* vector = ngGet_Vec_Info(&name[0]);
  if (!vector || !vector->v_realdata || vector->v_length < 1) {
    std::fprintf(stderr, "Missing vector %s\n", name.c_str());
    return {};
  }
  std::vector<double> values(vector->v_realdata, vector->v_realdata + vector->v_length);
  for (std::size_t i = 0; i < values.size(); ++i) {
    if (!std::isfinite(values[i])) {
      std::fprintf(stderr, "%s: non-finite value at sample %zu\n", name.c_str(), i);
      return {};
    }
  }
  return values;
}

std::vector<ngcomplex_t> ComplexValues(std::string name) {
  const auto* vector = ngGet_Vec_Info(&name[0]);
  if (!vector || !vector->v_compdata || vector->v_length < 1) {
    std::fprintf(stderr, "Missing complex vector %s\n", name.c_str());
    return {};
  }
  // ngGet_Vec_Info reuses one descriptor, so copy each result before another call.
  std::vector<ngcomplex_t> values(vector->v_compdata, vector->v_compdata + vector->v_length);
  for (std::size_t i = 0; i < values.size(); ++i) {
    if (!std::isfinite(values[i].cx_real) || !std::isfinite(values[i].cx_imag)) {
      std::fprintf(stderr, "%s: non-finite complex value at sample %zu\n", name.c_str(), i);
      return {};
    }
  }
  return values;
}

bool Expect(const char* name, double expected, double tolerance) {
  const auto values = Values(name);
  if (values.empty()) return false;
  const double actual = values.back();
  if (!std::isfinite(actual) || std::abs(actual - expected) > tolerance) {
    std::fprintf(stderr, "%s: expected %.12g, got %.12g\n", name, expected, actual);
    return false;
  }
  return true;
}

bool Feature(const char* banner, bool expected) {
  const bool actual = messages.find(banner) != std::string::npos;
  if (actual != expected) {
    std::fprintf(stderr, "Feature '%s': expected %s, got %s\n", banner,
                 expected ? "enabled" : "disabled", actual ? "enabled" : "disabled");
    return false;
  }
  return true;
}

bool KluRealAndComplex() {
  // A loaded RC divider exercises KLU's real and complex factorizations. Its
  // transfer function is 1 / (2 + j * 2*pi*f*R*C), so both parts have independent
  // analytic expectations instead of comparing two potentially broken solvers.
  messages.clear();
  if (!Circuit({"Bazel KLU real and complex solver", "Vsource input 0 DC 10 AC 1",
                "Rseries input output 1k", "Rload output 0 1k", "Cload output 0 1u",
                ".options klu", ".end"}, "op") ||
      !Feature("Using KLU as Direct Linear Solver", true) ||
      !Expect("v(output)", 5.0, 1e-8) ||
      !Expect("i(vsource)", -0.005, 1e-11)) return false;
  if (!Command("ac dec 4 10 100000")) return false;
  // Ngspice stores every AC vector, including frequency, as complex data.
  const auto frequencies = ComplexValues("frequency");
  const auto voltages = ComplexValues("v(output)");
  const auto currents = ComplexValues("i(vsource)");
  if (frequencies.size() != 17 || voltages.size() != 17 || currents.size() != 17)
    return false;
  for (std::size_t i = 0; i < frequencies.size(); ++i) {
    const double expected_frequency = 10.0 * std::pow(10.0, i / 4.0);
    const double omega_rc = 2.0 * std::acos(-1.0) * frequencies[i].cx_real * 0.001;
    const double expected_real = 2.0 / (4.0 + omega_rc * omega_rc);
    const double expected_imag = -omega_rc / (4.0 + omega_rc * omega_rc);
    const auto voltage = voltages[i];
    const auto current = currents[i];
    if (std::abs(frequencies[i].cx_real - expected_frequency) > 1e-9 * expected_frequency ||
        std::abs(frequencies[i].cx_imag) > 1e-12 ||
        std::abs(voltage.cx_real - expected_real) > 1e-9 ||
        std::abs(voltage.cx_imag - expected_imag) > 1e-9 ||
        std::abs(current.cx_real - (expected_real - 1.0) / 1000.0) > 1e-12 ||
        std::abs(current.cx_imag - expected_imag / 1000.0) > 1e-12) {
      std::fprintf(stderr, "KLU AC result differs from the RC transfer function at sample %zu\n", i);
      return false;
    }
  }
  // AC binds device pointers to complex entries; the next real solve must bind
  // them back correctly without destroying and recreating the circuit.
  return Command("op") && Expect("v(output)", 5.0, 1e-8) &&
         Expect("i(vsource)", -0.005, 1e-11);
}

bool BsimThreadComparison() {
  // Both BSIM3 and BSIM4 have parallel device evaluation paths. Multiple
  // instances exercise those loops; compare complete DC sweeps at 1 and 4 threads.
  std::vector<std::string> circuit = {
      "Bazel BSIM thread consistency", "Vdd3 drain3 0 1.2", "Vdd4 drain4 0 1.2",
      "Vgs gate 0 0", ".model n3 nmos level=8 version=3.3.0 vth0=0.45 k1=0.5 k2=0 u0=600",
      ".model n4 nmos level=14 version=4.8.3 vth0=0.45"};
  for (int i = 0; i < 16; ++i) {
    circuit.push_back("M3_" + std::to_string(i) + " drain3 gate 0 0 n3 W=10u L=1u");
    circuit.push_back("M4_" + std::to_string(i) + " drain4 gate 0 0 n4 W=10u L=1u");
  }
  circuit.push_back(".end");
  std::vector<double> reference3, reference4;
  for (const int threads : {1, 4}) {
    if (!Command("set num_threads=" + std::to_string(threads)) ||
        !Circuit(circuit, "dc vgs 0 1.2 0.1")) return false;
    const auto current3 = Values("i(vdd3)");
    const auto current4 = Values("i(vdd4)");
    if (!current3.empty() && !current4.empty()) {
      std::fprintf(stderr, "BSIM final drain currents: %.12g, %.12g\n",
                   current3.back(), current4.back());
    }
    if (current3.size() != 13 || current4.size() != 13 ||
        !(current3.back() < -1e-6) || !(current4.back() < -1e-6)) {
      std::fprintf(stderr, "BSIM DC sweep did not produce conducting transistor curves\n");
      return false;
    }
    if (threads == 1) {
      reference3 = current3;
      reference4 = current4;
      continue;
    }
    for (std::size_t i = 0; i < current3.size(); ++i) {
      for (const auto pair : {std::make_pair(reference3[i], current3[i]),
                              std::make_pair(reference4[i], current4[i])}) {
        if (std::abs(pair.first - pair.second) > 1e-12 + 1e-8 * std::abs(pair.first)) {
          std::fprintf(stderr, "BSIM 1-thread and 4-thread results differ at sample %zu\n", i);
          return false;
        }
      }
    }
  }
  return true;
}

#ifdef XSPICE
bool CheckDigitalEvents() {
  char** nodes = ngSpice_AllEvtNodes();
  if (!nodes) {
    std::fprintf(stderr, "The XSPICE API returned no event nodes\n");
    return false;
  }
  bool has_input = false, has_output = false;
  for (std::size_t i = 0; nodes[i]; ++i) {
    has_input |= std::string(nodes[i]) == "din";
    has_output |= std::string(nodes[i]) == "dout";
  }
  if (!has_input || !has_output) {
    std::fprintf(stderr, "The XSPICE API omitted the inverter's digital nodes\n");
    return false;
  }
  for (const auto expected : {std::make_pair("din", "0s"), std::make_pair("dout", "1s")}) {
    std::string name(expected.first);
    // Ngspice owns this result and invalidates it on the next event-info call.
    const auto* events = ngGet_Evt_NodeInfo(&name[0]);
    if (!events || events->num_steps < 1 || !events->evt_dect) {
      std::fprintf(stderr, "Missing XSPICE event history for %s\n", expected.first);
      return false;
    }
    for (int i = 0; i < events->num_steps; ++i) {
      if (!events->evt_dect[i] || !std::isfinite(events->evt_dect[i]->step)) {
        std::fprintf(stderr, "Invalid XSPICE event data for %s\n", expected.first);
        return false;
      }
    }
    const char* value = events->evt_dect[events->num_steps - 1]->node_value;
    // The public API encodes digital logic and drive strength as "0s" / "1s".
    if (!value || std::string(value) != expected.second) {
      std::fprintf(stderr, "%s: expected final event %s, got %s\n",
                   expected.first, expected.second, value ? value : "null");
      return false;
    }
  }
  return !simulator_exited && !simulator_error;
}
#endif
}  // namespace

int main(int argc, char** argv) {
  if (argc != 4) {
    std::fprintf(stderr, "Usage: %s install-tree xspice-enabled openmp-enabled\n", argv[0]);
    return 1;
  }
  const bool xspice = std::string(argv[2]) == "true";
  const bool openmp = std::string(argv[3]) == "true";
#ifdef XSPICE
  constexpr bool header_xspice = true;
#else
  constexpr bool header_xspice = false;
#endif
  if (header_xspice != xspice) {
    std::fprintf(stderr, "The public XSPICE define does not match the selected feature\n");
    return 1;
  }
  // Override system startup scripts and load this build's code models explicitly.
  // The upstream pre-init ngSpice_nospinit API crashes in ngspice 47.
  if (setenv("SPICE_SCRIPTS", "", 1) != 0) return 1;
  if (ngSpice_Init(Log, nullptr, Exit, nullptr, nullptr, nullptr, nullptr) != 0)
    return 1;
  messages.clear();
  if (!Command("version -f") ||
      !Feature("XSPICE extensions included", xspice) ||
      !Feature("OpenMP multithreading for BSIM3, BSIM4 enabled", openmp)) return 1;
  if (!Circuit({"Bazel voltage divider", "V1 in 0 10", "R1 in out 1k",
                "R2 out 0 1k", ".end"}, "op") ||
      !Expect("v(out)", 5.0, 1e-8) || !KluRealAndComplex() ||
      !BsimThreadComparison()) return 1;
  if (!xspice) return 0;
  // Loading every packaged code-model library also detects missing runtime assets.
  for (const auto* model : {"spice2poly", "analog", "digital", "xtradev",
                           "xtraevt", "table", "tlines"}) {
    const std::string path = std::string(argv[1]) + "/lib/ngspice/" + model + ".cm";
    messages.clear();
    if (!Command("codemodel \"" + path + "\"") || messages.find("Error") != std::string::npos)
      return 1;
  }
  if (!Circuit({"Bazel XSPICE analog gain", "V1 in 0 2", "A1 in out gain1",
                ".model gain1 gain(gain=3)", "R1 out 0 1k", ".end"}, "op") ||
      !Expect("v(out)", 6.0, 1e-8)) return 1;
  if (!Circuit({"Bazel XSPICE digital inverter", "V1 in 0 0",
                "Aadc [in] [din] adc", "Ainv din dout inv", "Adac [dout] [out] dac",
                "R1 out 0 1k", ".model adc adc_bridge(in_low=0.5 in_high=1.5)",
                ".model inv d_inverter(rise_delay=1n fall_delay=1n)",
                ".model dac dac_bridge(out_low=0 out_high=3.3 out_undef=1.65 t_rise=1n t_fall=1n)",
                ".end"}, "tran 1n 10n") ||
      !Expect("v(out)", 3.3, 1e-6)) return 1;
#ifdef XSPICE
  if (!CheckDigitalEvents()) return 1;
#endif
  return 0;
}
