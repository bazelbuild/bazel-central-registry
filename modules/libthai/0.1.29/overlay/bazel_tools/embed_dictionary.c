/* Encode the generated trie as a private, read-only C array. */
#include <stdio.h>

int main(int argc, char **argv) {
    if (argc != 3) return 1;
    FILE *input = fopen(argv[1], "rb");
    if (!input) { perror(argv[1]); return 1; }
    FILE *output = fopen(argv[2], "w");
    if (!output) { perror(argv[2]); fclose(input); return 1; }
    fputs("/* Generated from the upstream word lists. */\n"
          "static const unsigned char thbrk_dictionary[] = {\n", output);
    unsigned column = 0;
    int byte;
    while ((byte = fgetc(input)) != EOF) {
        fprintf(output, "0x%02x,", byte);
        if (++column % 16 == 0) fputc('\n', output);
    }
    fputs("\n};\n", output);
    int failed = ferror(input) || ferror(output);
    if (fclose(input) != 0) failed = 1;
    if (fclose(output) != 0) failed = 1;
    return failed ? 1 : 0;
}
