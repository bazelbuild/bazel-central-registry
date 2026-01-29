// ICU data symbol definition for Linux/GCC/Clang
// This assembly file creates the icudt78_dat symbol that ICU's udata.cpp expects.
// The .incbin directive includes the raw binary data from the .dat file.
    .globl icudt78_dat
    .section .rodata,"a",@progbits
    .balign 16
    .type icudt78_dat, @object
icudt78_dat:
    .incbin "external/icu~/source/data/in/icudt78l.dat"
    .size icudt78_dat, .-icudt78_dat
