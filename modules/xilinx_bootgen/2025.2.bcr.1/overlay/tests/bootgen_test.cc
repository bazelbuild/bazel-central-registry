/// @file
/// @brief Smoke test: bootgen builds a Zynq UltraScale+ boot image.
///
/// The inputs are written by the test itself (a minimal AArch64 ELF as the
/// bootloader, a data blob, a register-initialization file and the BIF naming
/// them), so the command-line, BIF and register-init parsers and the image
/// writer all run.  The program comes in as `BOOTGEN=<rlocationpath>` in the
/// environment.

#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

namespace {

/// @brief Offset of the image identification in the boot header (UG1085,
/// "Boot Header"): after the eight vector-table words and the width
/// detection word.
constexpr std::size_t IMAGE_ID_OFFSET = 0x24;

/// @brief The image identification string every boot header carries.
constexpr char IMAGE_ID[] = "XNLX";

/// @brief Size of the data blob used for the non-bootloader partitions.
constexpr std::size_t DATA_SIZE = 4096;

/// @brief Load and entry address of the bootloader ELF (on-chip memory).
constexpr std::uint64_t ELF_LOAD_ADDRESS = 0xFFFC0000;

/// @brief ELF `e_machine` value for AArch64.
constexpr std::uint16_t EM_AARCH64 = 183;

/// @brief Appends the low `bytes` bytes of `value`, little-endian.
/// @param out The byte vector to append to.
/// @param value The value to encode.
/// @param bytes How many bytes of it to write.
void put(std::vector<std::uint8_t>& out, std::uint64_t value, int bytes) {
  for (int i = 0; i < bytes; ++i) {
    out.push_back(static_cast<std::uint8_t>(value >> (8 * i)));
  }
}

/// @brief Builds a minimal ELF64 executable.
///
/// One PT_LOAD segment of AArch64 `b .` instructions, which is all bootgen
/// reads of a bootloader.
/// @return The bytes of the ELF file.
std::vector<std::uint8_t> minimal_elf() {
  const std::vector<std::uint8_t> code = {0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x14,
                                          0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x14};
  std::vector<std::uint8_t> elf = {0x7f, 'E', 'L', 'F', 2, 1, 1, 0};  // 64-bit, LE, v1
  elf.resize(16, 0);
  put(elf, 2, 2);                 // e_type: ET_EXEC
  put(elf, EM_AARCH64, 2);        // e_machine
  put(elf, 1, 4);                 // e_version
  put(elf, ELF_LOAD_ADDRESS, 8);  // e_entry
  put(elf, 64, 8);                // e_phoff: right after this header
  put(elf, 0, 8);                 // e_shoff: no sections
  put(elf, 0, 4);                 // e_flags
  put(elf, 64, 2);                // e_ehsize
  put(elf, 56, 2);                // e_phentsize
  put(elf, 1, 2);                 // e_phnum
  put(elf, 64, 2);                // e_shentsize
  put(elf, 0, 2);                 // e_shnum
  put(elf, 0, 2);                 // e_shstrndx
  put(elf, 1, 4);                 // p_type: PT_LOAD
  put(elf, 5, 4);                 // p_flags: PF_R | PF_X
  put(elf, 64 + 56, 8);           // p_offset: right after the headers
  put(elf, ELF_LOAD_ADDRESS, 8);  // p_vaddr
  put(elf, ELF_LOAD_ADDRESS, 8);  // p_paddr
  put(elf, code.size(), 8);       // p_filesz
  put(elf, code.size(), 8);       // p_memsz
  put(elf, 8, 8);                 // p_align
  elf.insert(elf.end(), code.begin(), code.end());
  return elf;
}

/// @brief Writes `bytes` to the file at `path`.
/// @param path The file to create or overwrite.
/// @param bytes Its contents.
/// @return Whether the write succeeded.
bool write_file(const std::string& path, const std::vector<std::uint8_t>& bytes) {
  std::ofstream out(path, std::ios::binary);
  out.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
  return out.good();
}

/// @brief Writes `text` to the file at `path`.
/// @param path The file to create or overwrite.
/// @param text Its contents.
/// @return Whether the write succeeded.
bool write_file(const std::string& path, const std::string& text) {
  return write_file(path, std::vector<std::uint8_t>(text.begin(), text.end()));
}

/// @brief Reads the whole file at `path`.
/// @param path The file to read.
/// @return Its bytes, empty if it cannot be read.
std::vector<std::uint8_t> read_file(const std::string& path) {
  std::ifstream in(path, std::ios::binary);
  return std::vector<std::uint8_t>((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

/// @brief Quotes a path for the shell `std::system` runs.
/// @param path The path to quote.
/// @return The quoted path: double quotes for cmd.exe, single quotes with
/// embedded quotes escaped for POSIX shells.
std::string quote(const std::string& path) {
#ifdef _WIN32
  return "\"" + path + "\"";
#else
  std::string out = "'";
  for (char c : path) {
    out += c == '\'' ? "'\\''" : std::string(1, c);
  }
  return out + "'";
#endif
}

/// @brief Reports a failure.
/// @param message What went wrong.
/// @return The process exit status to return, 1.
int fail(const std::string& message) {
  std::cerr << "FAIL: " << message << "\n";
  return 1;
}

}  // namespace

/// @brief Runs the smoke test.
/// @param argc Argument count, unused beyond runfiles discovery.
/// @param argv Argument vector; `argv[0]` locates the runfiles.
/// @return 0 when bootgen prints its usage and builds a well-formed image.
int main(int argc, char** argv) {
  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::Create(argv[0], &error));
  if (!runfiles) {
    return fail("runfiles: " + error);
  }
  const char* bootgen_rlocation = std::getenv("BOOTGEN");
  const char* tmpdir = std::getenv("TEST_TMPDIR");
  if (!bootgen_rlocation || !tmpdir) {
    return fail("BOOTGEN and TEST_TMPDIR must be set");
  }
  const std::string bootgen = quote(runfiles->Rlocation(bootgen_rlocation));
  const std::string dir = std::string(tmpdir) + "/";

  // The command-line parser alone: the usage text.
  if (std::system((bootgen + " -help").c_str()) != 0) {
    return fail("bootgen -help");
  }

  const std::string elf = dir + "fsbl.elf";
  const std::string data = dir + "data.bin";
  const std::string regs = dir + "regs.int";
  const std::string bif = dir + "boot.bif";
  const std::string image = dir + "boot.bin";
  if (!write_file(elf, minimal_elf()) || !write_file(data, std::vector<std::uint8_t>(DATA_SIZE, 0xA5)) ||
      // IOU_SLCR.MIO_PIN_0, a register the boot ROM lets the image set.
      !write_file(regs, ".set. 0xFF180000 = 0x00000002;\n") ||
      !write_file(bif, "the_ROM_image:\n"
                       "{\n"
                       "    [init] \"" + regs + "\"\n"
                       "    [bootloader, destination_cpu=a53-0] \"" + elf + "\"\n"
                       "    [destination_cpu=r5-0] \"" + data + "\"\n"
                       "    [destination_cpu=a53-1, exception_level=el-2, load=0x1000000] \"" + data + "\"\n"
                       "}\n")) {
    return fail("writing the inputs under " + dir);
  }

  const std::string command = bootgen + " -arch zynqmp -image " + quote(bif) + " -w on -o " + quote(image);
  if (std::system(command.c_str()) != 0) {
    return fail(command);
  }
  const std::vector<std::uint8_t> bytes = read_file(image);
  if (bytes.size() <= IMAGE_ID_OFFSET + sizeof(IMAGE_ID) || bytes.size() <= 2 * DATA_SIZE) {
    return fail("boot.bin is " + std::to_string(bytes.size()) + " bytes");
  }
  if (std::string(bytes.begin() + IMAGE_ID_OFFSET, bytes.begin() + IMAGE_ID_OFFSET + 4) != IMAGE_ID) {
    return fail("boot.bin does not carry the boot header's image identification");
  }
  std::cout << "PASS: " << bytes.size() << "-byte boot image\n";
  return 0;
}
