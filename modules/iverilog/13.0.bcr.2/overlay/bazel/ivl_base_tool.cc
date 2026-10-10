/**
 * @file ivl_base_tool.cc
 * @brief Process wrapper that copies files into a flat directory.
 *
 * Used by the ivl_base Starlark rule to assemble the IVL base directory
 * that the iverilog driver expects. Each file is copied to the output
 * directory under a specified destination name, allowing renaming (e.g.
 * libvvp_tgt.so -> vvp.tgt).
 *
 * Usage: ivl_base_tool <output_dir> -- <dest1>=<src1> <dest2>=<src2> ...
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>

#ifdef _WIN32
#include <direct.h>
#include <io.h>
#define mkdir_p(path) _mkdir(path)
#else
#include <sys/stat.h>
#include <sys/types.h>
#define mkdir_p(path) mkdir(path, 0755)
#endif

/** Create parent directories for a path, similar to mkdir -p. */
static int mkdirs(char *path) {
  for (char *p = path + 1; *p; ++p) {
    if (*p == '/' || *p == '\\') {
      *p = '\0';
      mkdir_p(path);
      *p = '/';
    }
  }
  return 0;
}

/** Copy a single file from src to dst. Returns 0 on success. */
static int copy_file(const char *src, const char *dst) {
  FILE *in = fopen(src, "rb");
  if (!in) {
    fprintf(stderr, "ivl_base_tool: cannot open source: %s\n", src);
    perror(src);
    return 1;
  }
  FILE *out = fopen(dst, "wb");
  if (!out) {
    fprintf(stderr, "ivl_base_tool: cannot create destination: %s\n", dst);
    perror(dst);
    fclose(in);
    return 1;
  }
  char buf[8192];
  size_t n;
  while ((n = fread(buf, 1, sizeof(buf), in)) > 0) {
    if (fwrite(buf, 1, n, out) != n) {
      fprintf(stderr, "ivl_base_tool: write error: %s\n", dst);
      fclose(in);
      fclose(out);
      return 1;
    }
  }
  int err = ferror(in);
  fclose(in);
  fclose(out);

#ifndef _WIN32
  /* Preserve execute permission for binaries. */
  struct stat st;
  if (stat(src, &st) == 0 && (st.st_mode & 0111)) {
    chmod(dst, st.st_mode);
  }
#endif

  return err;
}

/**
 * @brief Copies files into a directory with specified destination names.
 * @param argc Argument count (must be >= 3).
 * @param argv Arguments: <output_dir> -- <dest>=<src> ...
 * @return 0 on success, 1 on failure.
 */
int main(int argc, char *argv[]) {
  if (argc < 3) {
    fprintf(stderr,
            "usage: %s <output_dir> -- <dest1>=<src1> [<dest2>=<src2> ...]\n",
            argv[0]);
    return 1;
  }

  const char *output_dir = argv[1];
  if (strcmp(argv[2], "--") != 0) {
    fprintf(stderr, "expected '--' separator after output directory\n");
    return 1;
  }

  mkdir_p(output_dir);

  for (int i = 3; i < argc; ++i) {
    char *eq = strchr(argv[i], '=');
    if (!eq) {
      fprintf(stderr, "ivl_base_tool: malformed argument (expected dest=src): %s\n",
              argv[i]);
      return 1;
    }
    *eq = '\0';
    const char *dest_name = argv[i];
    const char *src_path = eq + 1;

    /* Build full destination path: output_dir/dest_name */
    char dst[4096];
    snprintf(dst, sizeof(dst), "%s/%s", output_dir, dest_name);

    /* Create subdirectories if needed (e.g. include/vpi_user.h). */
    char dst_copy[4096];
    strncpy(dst_copy, dst, sizeof(dst_copy) - 1);
    dst_copy[sizeof(dst_copy) - 1] = '\0';
    mkdirs(dst_copy);

    if (copy_file(src_path, dst) != 0) {
      return 1;
    }
  }

  return 0;
}
