/* Disassemble known byte sequences for the two CPU families Tracy cares about
 * most, through the module's public header path. */

#include <stdio.h>
#include <string.h>

#include <capstone/capstone.h>

static int check(cs_arch arch, cs_mode mode, const unsigned char* code, size_t size,
                 const char* const* expected, size_t expected_count) {
  csh handle;
  if (cs_open(arch, mode, &handle) != CS_ERR_OK) {
    fprintf(stderr, "cs_open(%d) failed\n", (int)arch);
    return 1;
  }
  cs_insn* insn = NULL;
  size_t count = cs_disasm(handle, code, size, 0x1000, 0, &insn);
  int rc = 0;
  if (count != expected_count) {
    fprintf(stderr, "arch %d: expected %zu instructions, got %zu\n", (int)arch, expected_count,
            count);
    rc = 1;
  }
  for (size_t i = 0; i < count && i < expected_count; ++i) {
    printf("0x%llx: %s %s\n", (unsigned long long)insn[i].address, insn[i].mnemonic,
           insn[i].op_str);
    if (strcmp(insn[i].mnemonic, expected[i]) != 0) {
      fprintf(stderr, "arch %d insn %zu: expected '%s', got '%s'\n", (int)arch, i, expected[i],
              insn[i].mnemonic);
      rc = 1;
    }
  }
  cs_free(insn, count);
  cs_close(&handle);
  return rc;
}

int main(void) {
  int major = 0, minor = 0;
  cs_version(&major, &minor);
  printf("capstone %d.%d\n", major, minor);
  if (major != 6) return 1;

  /* push rbp; mov rbp, rsp; xor eax, eax; ret */
  static const unsigned char x86[] = {0x55, 0x48, 0x89, 0xe5, 0x31, 0xc0, 0xc3};
  static const char* const x86_expected[] = {"push", "mov", "xor", "ret"};

  /* mov x0, #0; add x0, x0, #1; ret */
  static const unsigned char a64[] = {0x00, 0x00, 0x80, 0xd2, 0x00, 0x04, 0x00, 0x91,
                                      0xc0, 0x03, 0x5f, 0xd6};
  static const char* const a64_expected[] = {"mov", "add", "ret"};

  int rc = 0;
  rc |= check(CS_ARCH_X86, CS_MODE_64, x86, sizeof(x86), x86_expected, 4);
  rc |= check(CS_ARCH_AARCH64, CS_MODE_LITTLE_ENDIAN, a64, sizeof(a64), a64_expected, 3);
  return rc;
}
