/*
 * Checks that a Unicorn variant supports exactly its guest architectures.
 * EXPECT_<ARCH> is 1 for each architecture the linked variant must support;
 * every other architecture must be reported unsupported and fail uc_open().
 */
#include <stdio.h>
#include <unicorn/unicorn.h>

#ifndef EXPECT_ARM
#define EXPECT_ARM 0
#endif
#ifndef EXPECT_ARM64
#define EXPECT_ARM64 0
#endif
#ifndef EXPECT_X86
#define EXPECT_X86 0
#endif

struct check {
    const char *name;
    uc_arch arch;
    uc_mode mode;
    int expected;
};

int main(void) {
    const struct check checks[] = {
        {"ARM", UC_ARCH_ARM, UC_MODE_ARM, EXPECT_ARM},
        {"ARM64", UC_ARCH_ARM64, UC_MODE_ARM, EXPECT_ARM64},
        {"X86", UC_ARCH_X86, UC_MODE_64, EXPECT_X86},
        {"MIPS", UC_ARCH_MIPS, UC_MODE_MIPS32, 0},
        {"PPC", UC_ARCH_PPC, UC_MODE_PPC32 | UC_MODE_BIG_ENDIAN, 0},
        {"RISCV", UC_ARCH_RISCV, UC_MODE_RISCV64, 0},
    };
    int failures = 0;
    for (size_t i = 0; i < sizeof(checks) / sizeof(checks[0]); i++) {
        const struct check *c = &checks[i];
        int supported = uc_arch_supported(c->arch) ? 1 : 0;
        uc_engine *uc = NULL;
        uc_err err = uc_open(c->arch, c->mode, &uc);
        int opened = err == UC_ERR_OK;
        if (opened) {
            uc_close(uc);
        }
        printf("%-6s supported=%d opened=%d expected=%d\n", c->name, supported, opened,
               c->expected);
        if (supported != c->expected || opened != c->expected) {
            failures++;
        }
    }
    return failures != 0;
}
