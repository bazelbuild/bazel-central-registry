#include <ctype.h>
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Matches elfutils libcpu/Makefile.am's sed+sort pipeline for *.mnemonics. */

struct buffer {
  char *data;
  size_t len;
  size_t cap;
};

static void die(const char *message) {
  fprintf(stderr, "%s\n", message);
  exit(1);
}

static void *xrealloc(void *ptr, size_t size) {
  void *p = realloc(ptr, size);
  if (p == NULL) {
    die("out of memory");
  }
  return p;
}

static void buffer_reserve(struct buffer *buf, size_t extra) {
  size_t needed = buf->len + extra + 1;
  if (needed <= buf->cap) {
    return;
  }

  size_t cap = buf->cap == 0 ? 1024 : buf->cap;
  while (cap < needed) {
    cap *= 2;
  }
  buf->data = xrealloc(buf->data, cap);
  buf->cap = cap;
}

static void buffer_append(struct buffer *buf, const char *data, size_t len) {
  buffer_reserve(buf, len);
  memcpy(buf->data + buf->len, data, len);
  buf->len += len;
  buf->data[buf->len] = '\0';
}

static void buffer_append_char(struct buffer *buf, char c) {
  buffer_reserve(buf, 1);
  buf->data[buf->len++] = c;
  buf->data[buf->len] = '\0';
}

static char *read_file(const char *path, size_t *len) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    fprintf(stderr, "failed to open %s: %s\n", path, strerror(errno));
    exit(1);
  }

  struct buffer buf = {0};
  char chunk[8192];
  for (;;) {
    size_t n = fread(chunk, 1, sizeof(chunk), f);
    if (n > 0) {
      buffer_append(&buf, chunk, n);
    }
    if (n < sizeof(chunk)) {
      if (ferror(f)) {
        fprintf(stderr, "failed to read %s: %s\n", path, strerror(errno));
        exit(1);
      }
      break;
    }
  }

  if (fclose(f) != 0) {
    fprintf(stderr, "failed to close %s: %s\n", path, strerror(errno));
    exit(1);
  }

  *len = buf.len;
  return buf.data;
}

static char *mnemonic_from_line(const char *line, size_t len) {
  size_t pos = 0;
  while (pos < len && line[pos] != ':') {
    pos++;
  }
  if (pos == len) {
    return NULL;
  }

  pos++;
  size_t start = pos;
  while (pos < len && !isspace((unsigned char)line[pos])) {
    pos++;
  }
  if (pos == start) {
    return NULL;
  }

  struct buffer name = {0};
  for (size_t i = start; i < pos;) {
    if (line[i] == '{') {
      while (i < pos && line[i] != '}') {
        i++;
      }
      if (i < pos) {
        i++;
      }
    } else {
      buffer_append_char(&name, line[i++]);
    }
  }

  if (strstr(name.data, "INVALID") != NULL) {
    free(name.data);
    return NULL;
  }

  struct buffer mne = {0};
  buffer_append(&mne, "MNE(", strlen("MNE("));
  buffer_append(&mne, name.data, name.len);
  buffer_append_char(&mne, ')');
  free(name.data);
  return mne.data;
}

static int compare_strings(const void *a, const void *b) {
  const char *const *sa = a;
  const char *const *sb = b;
  return strcmp(*sa, *sb);
}

static void add_mnemonic(char ***items, size_t *len, size_t *cap, char *item) {
  if (*len == *cap) {
    *cap = *cap == 0 ? 256 : *cap * 2;
    *items = xrealloc(*items, *cap * sizeof(**items));
  }
  (*items)[(*len)++] = item;
}

static void write_mnemonics(const char *expanded, size_t expanded_len,
                            const char *out_path) {
  size_t pos = 0;
  bool past_separator = false;
  char **items = NULL;
  size_t item_count = 0;
  size_t item_cap = 0;

  while (pos < expanded_len) {
    size_t line_start = pos;
    while (pos < expanded_len && expanded[pos] != '\n') {
      pos++;
    }
    size_t line_len = pos - line_start;
    if (pos < expanded_len && expanded[pos] == '\n') {
      pos++;
    }

    const char *line = expanded + line_start;
    if (!past_separator) {
      if (line_len >= 2 && line[0] == '%' && line[1] == '%') {
        past_separator = true;
      }
      continue;
    }

    if (line_len > 0 && line[line_len - 1] == '\r') {
      line_len--;
    }
    if (line_len > 0 && line[0] == '#') {
      continue;
    }

    bool blank = true;
    for (size_t i = 0; i < line_len; i++) {
      if (!isspace((unsigned char)line[i])) {
        blank = false;
        break;
      }
    }
    if (blank) {
      continue;
    }

    char *mnemonic = mnemonic_from_line(line, line_len);
    if (mnemonic != NULL) {
      add_mnemonic(&items, &item_count, &item_cap, mnemonic);
    }
  }

  if (!past_separator) {
    die("missing %% separator");
  }

  qsort(items, item_count, sizeof(*items), compare_strings);

  FILE *out = fopen(out_path, "wb");
  if (out == NULL) {
    fprintf(stderr, "failed to open %s: %s\n", out_path, strerror(errno));
    exit(1);
  }

  const char *previous = NULL;
  for (size_t i = 0; i < item_count; i++) {
    if (previous != NULL && strcmp(previous, items[i]) == 0) {
      continue;
    }
    if (fprintf(out, "%s\n", items[i]) < 0) {
      fprintf(stderr, "failed to write %s: %s\n", out_path, strerror(errno));
      exit(1);
    }
    previous = items[i];
  }

  for (size_t i = 0; i < item_count; i++) {
    free(items[i]);
  }
  free(items);

  if (fclose(out) != 0) {
    fprintf(stderr, "failed to close %s: %s\n", out_path, strerror(errno));
    exit(1);
  }
}

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "usage: %s EXPANDED_DEFS OUT\n", argv[0]);
    return 1;
  }

  size_t input_len = 0;
  char *input = read_file(argv[1], &input_len);
  write_mnemonics(input, input_len, argv[2]);

  free(input);
  return 0;
}
