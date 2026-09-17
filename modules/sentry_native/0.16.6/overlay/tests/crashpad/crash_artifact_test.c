#include <sentry.h>

#include <arpa/inet.h>
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <netinet/in.h>
#include <poll.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>
#include <zlib.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

static bool ends_with(const char *value, const char *suffix) {
  size_t value_len = strlen(value);
  size_t suffix_len = strlen(suffix);
  return value_len >= suffix_len &&
         memcmp(value + value_len - suffix_len, suffix, suffix_len) == 0;
}

static int join_path(char *output, size_t output_size, const char *directory,
                     const char *entry) {
  int length = snprintf(output, output_size, "%s/%s", directory, entry);
  return length >= 0 && (size_t)length < output_size ? 0 : -1;
}

static const char *find_header(const char *headers, const char *name) {
  size_t name_len = strlen(name);
  for (const char *cursor = headers; *cursor; cursor++) {
    size_t i = 0;
    while (i < name_len && cursor[i] &&
           tolower((unsigned char)cursor[i]) ==
               tolower((unsigned char)name[i])) {
      i++;
    }
    if (i == name_len) {
      return cursor;
    }
  }
  return NULL;
}

static bool contains_bytes(const unsigned char *haystack, size_t haystack_len,
                           const unsigned char *needle, size_t needle_len) {
  if (needle_len == 0 || needle_len > haystack_len) {
    return false;
  }
  for (size_t i = 0; i <= haystack_len - needle_len; i++) {
    if (memcmp(haystack + i, needle, needle_len) == 0) {
      return true;
    }
  }
  return false;
}

static int decode_chunked(const unsigned char *encoded, size_t encoded_len,
                          unsigned char **decoded, size_t *decoded_len) {
  unsigned char *output = malloc(encoded_len ? encoded_len : 1);
  if (!output) {
    return -1;
  }

  size_t input_offset = 0;
  size_t output_offset = 0;
  while (input_offset < encoded_len) {
    size_t line_end = input_offset;
    while (line_end + 1 < encoded_len &&
           !(encoded[line_end] == '\r' && encoded[line_end + 1] == '\n')) {
      line_end++;
    }
    if (line_end + 1 >= encoded_len || line_end - input_offset >= 32) {
      free(output);
      return 1;
    }

    char size_text[32];
    size_t size_len = line_end - input_offset;
    memcpy(size_text, encoded + input_offset, size_len);
    size_text[size_len] = '\0';
    char *end = NULL;
    unsigned long long chunk_size = strtoull(size_text, &end, 16);
    if (end == size_text || (*end && *end != ';')) {
      free(output);
      return -1;
    }
    input_offset = line_end + 2;
    if (chunk_size == 0) {
      *decoded = output;
      *decoded_len = output_offset;
      return 0;
    }
    if (chunk_size > encoded_len - input_offset ||
        encoded_len - input_offset - (size_t)chunk_size < 2) {
      free(output);
      return 1;
    }
    memcpy(output + output_offset, encoded + input_offset, (size_t)chunk_size);
    output_offset += (size_t)chunk_size;
    input_offset += (size_t)chunk_size;
    if (encoded[input_offset] != '\r' || encoded[input_offset + 1] != '\n') {
      free(output);
      return -1;
    }
    input_offset += 2;
  }

  free(output);
  return 1;
}

static int gunzip(const unsigned char *compressed, size_t compressed_len,
                  unsigned char **uncompressed, size_t *uncompressed_len) {
  size_t capacity = 1024 * 1024;
  unsigned char *output = malloc(capacity);
  if (!output) {
    return -1;
  }

  z_stream stream = {0};
  stream.next_in = (unsigned char *)compressed;
  stream.avail_in = (unsigned int)compressed_len;
  if (inflateInit2(&stream, MAX_WBITS + 16) != Z_OK) {
    free(output);
    return -1;
  }

  int result = Z_OK;
  while (result == Z_OK) {
    if (stream.total_out == capacity) {
      if (capacity >= 64 * 1024 * 1024) {
        result = Z_MEM_ERROR;
        break;
      }
      capacity *= 2;
      unsigned char *resized = realloc(output, capacity);
      if (!resized) {
        result = Z_MEM_ERROR;
        break;
      }
      output = resized;
    }
    stream.next_out = output + stream.total_out;
    stream.avail_out = (unsigned int)(capacity - stream.total_out);
    result = inflate(&stream, Z_NO_FLUSH);
  }

  if (result != Z_STREAM_END) {
    inflateEnd(&stream);
    free(output);
    return -1;
  }
  *uncompressed_len = (size_t)stream.total_out;
  *uncompressed = output;
  inflateEnd(&stream);
  return 0;
}

static int open_listener(unsigned *port) {
  int listener = socket(AF_INET, SOCK_STREAM, 0);
  if (listener < 0) {
    return -1;
  }

  struct sockaddr_in address = {
      .sin_family = AF_INET,
      .sin_addr.s_addr = htonl(INADDR_LOOPBACK),
      .sin_port = 0,
  };
  if (bind(listener, (struct sockaddr *)&address, sizeof(address)) != 0 ||
      listen(listener, 1) != 0) {
    close(listener);
    return -1;
  }

  socklen_t address_len = sizeof(address);
  if (getsockname(listener, (struct sockaddr *)&address, &address_len) != 0) {
    close(listener);
    return -1;
  }
  *port = (unsigned)ntohs(address.sin_port);
  return listener;
}

static int receive_crash_upload(int listener) {
  struct pollfd event = {
      .fd = listener,
      .events = POLLIN,
  };
  int ready;
  do {
    ready = poll(&event, 1, 30000);
  } while (ready < 0 && errno == EINTR);
  if (ready != 1 || !(event.revents & POLLIN)) {
    fprintf(stderr, "timed out waiting for Crashpad upload: %s\n",
            ready < 0 ? strerror(errno) : "no readable connection");
    close(listener);
    return 1;
  }

  int client = accept(listener, NULL, NULL);
  close(listener);
  if (client < 0) {
    return 1;
  }

  size_t capacity = 64 * 1024;
  size_t length = 0;
  size_t expected_body = 0;
  size_t header_length = 0;
  bool chunked = false;
  bool gzip_body = false;
  unsigned char *request = malloc(capacity);
  if (!request) {
    close(client);
    return 1;
  }

  while (length < 64 * 1024 * 1024) {
    if (length + 1 == capacity) {
      size_t new_capacity = capacity * 2;
      unsigned char *resized = realloc(request, new_capacity);
      if (!resized) {
        free(request);
        close(client);
        return 1;
      }
      request = resized;
      capacity = new_capacity;
    }

    ssize_t received = recv(client, request + length, capacity - length - 1, 0);
    if (received <= 0) {
      break;
    }
    length += (size_t)received;
    request[length] = '\0';

    if (header_length == 0) {
      unsigned char *body =
          (unsigned char *)strstr((const char *)request, "\r\n\r\n");
      if (body) {
        header_length = (size_t)(body + 4 - request);
        const char *content_length =
            find_header((const char *)request, "content-length:");
        chunked = find_header((const char *)request,
                              "transfer-encoding: chunked") != NULL;
        gzip_body = find_header((const char *)request,
                                "content-encoding: gzip") != NULL;
        if (!content_length && !chunked) {
          break;
        }
        if (content_length) {
          expected_body = (size_t)strtoull(
              content_length + strlen("content-length:"), NULL, 10);
          size_t required_capacity = header_length + expected_body + 1;
          if (required_capacity > 64 * 1024 * 1024) {
            break;
          }
          if (required_capacity > capacity) {
            unsigned char *resized = realloc(request, required_capacity);
            if (!resized) {
              break;
            }
            request = resized;
            capacity = required_capacity;
          }
        }
      }
    }
    if (header_length) {
      if (!chunked && length >= header_length + expected_body) {
        break;
      }
      static const unsigned char terminator[] = "\r\n0\r\n\r\n";
      if (chunked &&
          contains_bytes(request + header_length, length - header_length,
                         terminator, sizeof(terminator) - 1)) {
        break;
      }
    }
  }

  static const char response[] =
      "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
  (void)send(client, response, sizeof(response) - 1, 0);
  close(client);

  unsigned char *decoded_body = NULL;
  size_t decoded_length = 0;
  int decode_result = -1;
  if (header_length) {
    if (chunked) {
      decode_result =
          decode_chunked(request + header_length, length - header_length,
                         &decoded_body, &decoded_length);
    } else if (expected_body && length >= header_length + expected_body) {
      decoded_body = malloc(expected_body);
      if (decoded_body) {
        memcpy(decoded_body, request + header_length, expected_body);
        decoded_length = expected_body;
        decode_result = 0;
      }
    }
  }

  unsigned char *upload_body = decoded_body;
  size_t upload_length = decoded_length;
  unsigned char *uncompressed = NULL;
  size_t uncompressed_length = 0;
  if (decode_result == 0 && gzip_body) {
    if (gunzip(decoded_body, decoded_length, &uncompressed,
               &uncompressed_length) != 0) {
      decode_result = -1;
    } else {
      upload_body = uncompressed;
      upload_length = uncompressed_length;
    }
  }

  bool complete = decode_result == 0 && upload_length > 0;
  bool has_minidump =
      complete && contains_bytes(upload_body, upload_length,
                                 (const unsigned char *)"MDMP", 4);
  bool has_integrations =
      complete && contains_bytes(upload_body, upload_length,
                                 (const unsigned char *)"integrations",
                                 strlen("integrations"));
  bool has_crashpad =
      complete &&
      contains_bytes(upload_body, upload_length,
                     (const unsigned char *)"crashpad", strlen("crashpad"));
  bool has_fatal = complete && contains_bytes(upload_body, upload_length,
                                              (const unsigned char *)"fatal",
                                              strlen("fatal"));
  int result = 0;
  if (!complete || !has_minidump || !has_integrations || !has_crashpad ||
      !has_fatal) {
    fprintf(stderr,
            "Crashpad multipart upload invalid: length=%zu headers=%zu "
            "body=%zu complete=%d minidump=%d integrations=%d crashpad=%d "
            "fatal=%d\n",
            length, header_length, upload_length, complete, has_minidump,
            has_integrations, has_crashpad, has_fatal);
    if (header_length) {
      fwrite(request, 1, header_length, stderr);
    }
    result = 1;
  }
  free(uncompressed);
  free(decoded_body);
  free(request);
  return result;
}

static int find_minidump(const char *database_path, char *output,
                         size_t output_size) {
  static const char *directories[] = {"new", "pending", "completed"};
  for (size_t i = 0; i < sizeof(directories) / sizeof(directories[0]); i++) {
    char directory_path[PATH_MAX];
    if (join_path(directory_path, sizeof(directory_path), database_path,
                  directories[i]) != 0) {
      return -1;
    }

    DIR *directory = opendir(directory_path);
    if (!directory) {
      continue;
    }

    struct dirent *entry;
    while ((entry = readdir(directory)) != NULL) {
      if (!ends_with(entry->d_name, ".dmp")) {
        continue;
      }
      int result =
          join_path(output, output_size, directory_path, entry->d_name);
      closedir(directory);
      return result;
    }
    closedir(directory);
  }
  return 1;
}

static int wait_for_minidump(const char *database_path, char *output,
                             size_t output_size) {
  const struct timespec interval = {0, 100 * 1000 * 1000};
  for (size_t attempt = 0; attempt < 100; attempt++) {
    int result = find_minidump(database_path, output, output_size);
    if (result <= 0) {
      return result;
    }
    nanosleep(&interval, NULL);
  }
  return 1;
}

static int assert_minidump(const char *path) {
  struct stat metadata;
  if (lstat(path, &metadata) != 0 || !S_ISREG(metadata.st_mode) ||
      metadata.st_size < 4) {
    fprintf(stderr, "invalid Crashpad minidump: %s\n", path);
    return 1;
  }

  FILE *file = fopen(path, "rb");
  unsigned char magic[4];
  if (!file || fread(magic, 1, sizeof(magic), file) != sizeof(magic)) {
    fprintf(stderr, "could not read Crashpad minidump %s: %s\n", path,
            strerror(errno));
    if (file) {
      fclose(file);
    }
    return 1;
  }
  fclose(file);

  if (memcmp(magic, "MDMP", sizeof(magic)) != 0) {
    fprintf(stderr, "Crashpad report lacks MDMP magic: %s\n", path);
    return 1;
  }
  return 0;
}

static void run_crashing_child(const char *database_path,
                               const char *handler_path, unsigned port) {
  sentry_options_t *options = sentry_options_new();
  if (!options) {
    _exit(90);
  }
  sentry_options_set_database_path(options, database_path);
  sentry_options_set_handler_path(options, handler_path);
  sentry_options_set_auto_session_tracking(options, 0);
  sentry_options_set_crashpad_wait_for_upload(options, 1);
  char dsn[128];
  snprintf(dsn, sizeof(dsn), "http://public@127.0.0.1:%u/1", port);
  sentry_options_set_dsn(options, dsn);
  if (sentry_init(options) != 0) {
    _exit(91);
  }

  sentry_crash();
  _exit(92);
}

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "usage: %s /path/to/crashpad_handler\n", argv[0]);
    return 1;
  }

  unsigned port = 0;
  int listener = open_listener(&port);
  if (listener < 0) {
    fprintf(stderr, "could not open loopback HTTP listener: %s\n",
            strerror(errno));
    return 1;
  }

  const char *test_tmpdir = getenv("TEST_TMPDIR");
  if (!test_tmpdir || !test_tmpdir[0]) {
    fprintf(stderr, "TEST_TMPDIR is required\n");
    return 1;
  }

  char database_path[PATH_MAX];
  int length = snprintf(database_path, sizeof(database_path),
                        "%s/crashpad-db-%ld", test_tmpdir, (long)getpid());
  if (length < 0 || (size_t)length >= sizeof(database_path)) {
    fprintf(stderr, "isolated database path exceeds PATH_MAX\n");
    return 1;
  }

  pid_t child = fork();
  if (child < 0) {
    close(listener);
    fprintf(stderr, "fork failed: %s\n", strerror(errno));
    return 1;
  }
  if (child == 0) {
    close(listener);
    run_crashing_child(database_path, argv[1], port);
  }

  int upload_result = receive_crash_upload(listener);

  int status = 0;
  if (waitpid(child, &status, 0) != child) {
    fprintf(stderr, "waitpid failed: %s\n", strerror(errno));
    return 1;
  }
  if (upload_result != 0) {
    return upload_result;
  }
  if (!WIFSIGNALED(status) &&
      !(WIFEXITED(status) && WEXITSTATUS(status) != 0)) {
    fprintf(stderr, "child did not terminate through Crashpad (status %d)\n",
            status);
    return 1;
  }

  char minidump_path[PATH_MAX] = {0};
  if (wait_for_minidump(database_path, minidump_path, sizeof(minidump_path)) !=
      0) {
    fprintf(stderr, "Crashpad did not persist a minidump under %s\n",
            database_path);
    return 1;
  }
  return assert_minidump(minidump_path);
}
