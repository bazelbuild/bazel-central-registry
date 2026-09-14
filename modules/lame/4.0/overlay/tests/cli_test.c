#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <io.h>
#include <process.h>
#else
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

static int run_lame(char *const args[], const char *output_path) {
  FILE *output = fopen(output_path, "wb");
  if (output == NULL) {
    perror(output_path);
    return 1;
  }

#ifdef _WIN32
  int saved_stdout = _dup(_fileno(stdout));
  if (saved_stdout < 0 || _dup2(_fileno(output), _fileno(stdout)) < 0) {
    perror("redirect stdout");
    fclose(output);
    if (saved_stdout >= 0)
      _close(saved_stdout);
    return 1;
  }
  intptr_t status = _spawnv(_P_WAIT, args[0], (const char *const *)args);
  int restored = _dup2(saved_stdout, _fileno(stdout));
  _close(saved_stdout);
  fclose(output);
  if (status != 0 || restored < 0) {
    fprintf(stderr, "LAME failed or stdout could not be restored\n");
    return 1;
  }
#else
  pid_t child = fork();
  if (child == -1) {
    perror("fork");
    fclose(output);
    return 1;
  }
  if (child == 0) {
    if (dup2(fileno(output), STDOUT_FILENO) == -1) {
      perror("redirect stdout");
      _exit(1);
    }
    execv(args[0], args);
    perror(args[0]);
    _exit(1);
  }
  fclose(output);
  int status;
  while (waitpid(child, &status, 0) == -1) {
    if (errno != EINTR) {
      perror("waitpid");
      return 1;
    }
  }
  if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
    fprintf(stderr, "LAME did not exit successfully\n");
    return 1;
  }
#endif
  return 0;
}

static int check_output(const char *path, const char *expected) {
  FILE *output = fopen(path, "rb");
  if (output == NULL) {
    perror(path);
    return 1;
  }
  char text[16384];
  size_t length = fread(text, 1, sizeof(text) - 1, output);
  int read_failed = ferror(output);
  fclose(output);
  text[length] = '\0';
  if (read_failed || strstr(text, "LAME ") == NULL ||
      strstr(text, expected) == NULL) {
    fprintf(stderr, "expected '%s' in LAME output:\n%s", expected, text);
    return 1;
  }
  return 0;
}

static long file_size(FILE *file) {
  if (fseek(file, 0, SEEK_END) != 0)
    return -1;
  long size = ftell(file);
  rewind(file);
  return size;
}

static int check_mp3(const char *encoded_path, const char *reference_path) {
  FILE *encoded = fopen(encoded_path, "rb");
  FILE *reference = fopen(reference_path, "rb");
  if (encoded == NULL || reference == NULL) {
    fprintf(stderr, "cannot open encoded MP3 and upstream MP3 fixture\n");
    if (encoded != NULL)
      fclose(encoded);
    if (reference != NULL)
      fclose(reference);
    return 1;
  }
  long encoded_size = file_size(encoded);
  long reference_size = file_size(reference);
  fclose(reference);
  if (reference_size <= 0 || encoded_size < reference_size / 2 ||
      encoded_size > reference_size * 2) {
    fprintf(stderr, "unexpected CLI MP3 size: encoded %ld, reference %ld\n",
            encoded_size, reference_size);
    fclose(encoded);
    return 1;
  }

  long offset = 0;
  while (offset < encoded_size) {
    unsigned char header[4];
    // testcase.wav is stereo 44.1 kHz PCM; lame_bin is given a 128 kbps CBR
    // option.
    if (fread(header, 1, sizeof(header), encoded) != sizeof(header) ||
        header[0] != 0xff || (header[1] & 0xfe) != 0xfa ||
        (header[2] & 0xfc) != 0x90 || (header[3] & 0xc0) == 0xc0) {
      fprintf(stderr, "invalid MPEG-1 Layer III header at byte %ld\n", offset);
      fclose(encoded);
      return 1;
    }
    long frame_size = 144000 * 128 / 44100 + ((header[2] >> 1) & 1);
    if (frame_size > encoded_size - offset ||
        fseek(encoded, frame_size - sizeof(header), SEEK_CUR) != 0) {
      fprintf(stderr, "truncated MPEG-1 Layer III frame at byte %ld\n", offset);
      fclose(encoded);
      return 1;
    }
    offset += frame_size;
  }
  fclose(encoded);
  return 0;
}

int main(int argc, char **argv) {
  if (argc != 3 && argc != 5)
    return 1;
  const char *tmpdir = getenv("TEST_TMPDIR");
  if (tmpdir == NULL) {
    fprintf(stderr, "TEST_TMPDIR is not set\n");
    return 1;
  }
  char output_path[4096];
  int length =
      snprintf(output_path, sizeof(output_path), "%s/cli-output.txt", tmpdir);
  if (length < 0 || (size_t)length >= sizeof(output_path))
    return 1;

  if (argc == 3) {
    const char *expected;
    if (strcmp(argv[2], "--version") == 0) {
      expected = "version 4.0";
    } else if (strcmp(argv[2], "--help") == 0) {
      expected = "[options] <infile> [outfile]";
    } else {
      return 1;
    }
    char *args[] = {argv[1], argv[2], NULL};
    return run_lame(args, output_path) || check_output(output_path, expected);
  }

  if (strcmp(argv[2], "encode") != 0)
    return 1;
  char encoded_path[4096];
  length =
      snprintf(encoded_path, sizeof(encoded_path), "%s/testcase.mp3", tmpdir);
  if (length < 0 || (size_t)length >= sizeof(encoded_path))
    return 1;
  char *args[] = {argv[1], "--silent", "--nores",    "--cbr", "-b",
                  "128",   argv[3],    encoded_path, NULL};
  return run_lame(args, output_path) || check_mp3(encoded_path, argv[4]);
}
