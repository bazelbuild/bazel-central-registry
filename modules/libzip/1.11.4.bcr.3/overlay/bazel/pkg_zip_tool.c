#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <zip.h>

struct archive_list {
    zip_t **items;
    size_t count;
    size_t capacity;
};

static void
usage(const char *progname) {
    fprintf(stderr, "usage: %s OUT MANIFEST\n", progname);
}

static void
close_archives(struct archive_list *archives) {
    size_t i;

    for (i = 0; i < archives->count; i++) {
        zip_close(archives->items[i]);
    }
    free(archives->items);
    archives->items = NULL;
    archives->count = 0;
    archives->capacity = 0;
}

static int
remember_archive(struct archive_list *archives, zip_t *archive) {
    zip_t **items;
    size_t capacity;

    if (archives->count < archives->capacity) {
        archives->items[archives->count++] = archive;
        return 0;
    }

    capacity = archives->capacity == 0 ? 4 : archives->capacity * 2;
    items = (zip_t **)realloc(archives->items, capacity * sizeof(archives->items[0]));
    if (items == NULL) {
        return -1;
    }

    archives->items = items;
    archives->capacity = capacity;
    archives->items[archives->count++] = archive;
    return 0;
}

static int
parse_mode(const char *text, unsigned int *mode) {
    char *end = NULL;
    unsigned long value;

    errno = 0;
    value = strtoul(text, &end, 8);
    if (errno != 0 || end == text || *end != '\0' || value > 07777) {
        return -1;
    }

    *mode = (unsigned int)value;
    return 0;
}

static int
ensure_absent(zip_t *archive, const char *zip_path) {
    if (zip_name_locate(archive, zip_path, 0) >= 0) {
        fprintf(stderr, "error: duplicate zip entry '%s'\n", zip_path);
        return -1;
    }
    return 0;
}

static int
add_file(zip_t *archive, const char *source_path, const char *zip_path, unsigned int mode) {
    zip_source_t *source;
    zip_int64_t index;

    if (ensure_absent(archive, zip_path) < 0) {
        return -1;
    }

    source = zip_source_file_create(source_path, 0, ZIP_LENGTH_TO_END, NULL);
    if (source == NULL) {
        fprintf(stderr, "error: cannot create source for '%s'\n", source_path);
        return -1;
    }

    index = zip_file_add(archive, zip_path, source, 0);
    if (index < 0) {
        fprintf(stderr, "error: cannot add '%s' as '%s': %s\n", source_path, zip_path, zip_strerror(archive));
        zip_source_free(source);
        return -1;
    }

    if (zip_file_set_external_attributes(archive, (zip_uint64_t)index, 0, ZIP_OPSYS_UNIX, mode << 16) < 0) {
        fprintf(stderr, "error: cannot set mode for '%s': %s\n", zip_path, zip_strerror(archive));
        return -1;
    }

    return 0;
}

static int
copy_external_attributes(zip_t *dst, zip_uint64_t dst_index, zip_t *src, zip_uint64_t src_index, const char *zip_path) {
    zip_uint8_t opsys;
    zip_uint32_t attributes;

    if (zip_file_get_external_attributes(src, src_index, ZIP_FL_UNCHANGED, &opsys, &attributes) < 0) {
        return 0;
    }

    if (zip_file_set_external_attributes(dst, dst_index, 0, opsys, attributes) < 0) {
        fprintf(stderr, "error: cannot set attributes for '%s': %s\n", zip_path, zip_strerror(dst));
        return -1;
    }

    return 0;
}

static int
copy_entry(zip_t *dst, zip_t *src, zip_uint64_t src_index, const char *zip_path) {
    zip_source_t *source;
    zip_int64_t dst_index;
    size_t len;

    if (ensure_absent(dst, zip_path) < 0) {
        return -1;
    }

    len = strlen(zip_path);
    if (len > 0 && zip_path[len - 1] == '/') {
        dst_index = zip_dir_add(dst, zip_path, 0);
        if (dst_index < 0) {
            fprintf(stderr, "error: cannot add directory '%s': %s\n", zip_path, zip_strerror(dst));
            return -1;
        }
        return copy_external_attributes(dst, (zip_uint64_t)dst_index, src, src_index, zip_path);
    }

    source = zip_source_zip_file_create(src, src_index, ZIP_FL_UNCHANGED, 0, -1, NULL, NULL);
    if (source == NULL) {
        fprintf(stderr, "error: cannot create source for zip entry '%s'\n", zip_path);
        return -1;
    }

    dst_index = zip_file_add(dst, zip_path, source, 0);
    if (dst_index < 0) {
        fprintf(stderr, "error: cannot add zip entry '%s': %s\n", zip_path, zip_strerror(dst));
        zip_source_free(source);
        return -1;
    }

    return copy_external_attributes(dst, (zip_uint64_t)dst_index, src, src_index, zip_path);
}

static int
merge_zip(zip_t *dst, const char *zip_path, struct archive_list *archives) {
    zip_t *src;
    zip_int64_t num_entries;
    zip_uint64_t i;
    int error_code = 0;

    src = zip_open(zip_path, ZIP_RDONLY, &error_code);
    if (src == NULL) {
        fprintf(stderr, "error: cannot open input zip '%s' (error %d)\n", zip_path, error_code);
        return -1;
    }

    num_entries = zip_get_num_entries(src, 0);
    if (num_entries < 0) {
        fprintf(stderr, "error: cannot enumerate input zip '%s': %s\n", zip_path, zip_strerror(src));
        zip_close(src);
        return -1;
    }

    for (i = 0; i < (zip_uint64_t)num_entries; i++) {
        const char *entry_name = zip_get_name(src, i, 0);
        if (entry_name == NULL) {
            fprintf(stderr, "error: cannot read entry name in '%s': %s\n", zip_path, zip_strerror(src));
            zip_close(src);
            return -1;
        }

        if (copy_entry(dst, src, i, entry_name) < 0) {
            zip_close(src);
            return -1;
        }
    }

    if (remember_archive(archives, src) < 0) {
        fprintf(stderr, "error: out of memory while merging '%s'\n", zip_path);
        zip_close(src);
        return -1;
    }

    return 0;
}

static char *
strip_newline(char *line) {
    size_t len = strlen(line);

    while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r')) {
        line[--len] = '\0';
    }

    return line;
}

int
main(int argc, char **argv) {
    const char *out_path;
    const char *manifest_path;
    FILE *manifest;
    zip_t *archive;
    struct archive_list archives;
    zip_error_t error;
    char line[65536];
    unsigned int line_number = 0;

    if (argc != 3) {
        usage(argv[0]);
        return 2;
    }

    out_path = argv[1];
    manifest_path = argv[2];

    manifest = fopen(manifest_path, "r");
    if (manifest == NULL) {
        fprintf(stderr, "error: cannot open manifest '%s': %s\n", manifest_path, strerror(errno));
        return 1;
    }

    zip_error_init(&error);
    memset(&archives, 0, sizeof(archives));
    archive = zip_open(out_path, ZIP_CREATE | ZIP_TRUNCATE, NULL);
    if (archive == NULL) {
        zip_error_set(&error, ZIP_ER_OPEN, errno);
        fprintf(stderr, "error: cannot create zip '%s': %s\n", out_path, zip_error_strerror(&error));
        fclose(manifest);
        zip_error_fini(&error);
        return 1;
    }

    while (fgets(line, sizeof(line), manifest) != NULL) {
        char *kind;
        char *source_path;
        char *zip_path;
        char *mode_text;
        char *tab;
        unsigned int mode;

        line_number++;
        strip_newline(line);

        kind = line;
        tab = strchr(kind, '\t');
        if (tab == NULL) {
            fprintf(stderr, "error: malformed manifest line %u\n", line_number);
            zip_discard(archive);
            close_archives(&archives);
            fclose(manifest);
            zip_error_fini(&error);
            return 1;
        }
        *tab = '\0';

        if (strcmp(kind, "Z") == 0) {
            if (merge_zip(archive, tab + 1, &archives) < 0) {
                zip_discard(archive);
                close_archives(&archives);
                fclose(manifest);
                zip_error_fini(&error);
                return 1;
            }
            continue;
        }

        if (strcmp(kind, "F") != 0) {
            fprintf(stderr, "error: unknown manifest entry kind '%s' on line %u\n", kind, line_number);
            zip_discard(archive);
            close_archives(&archives);
            fclose(manifest);
            zip_error_fini(&error);
            return 1;
        }

        source_path = tab + 1;
        tab = strchr(source_path, '\t');
        if (tab == NULL) {
            fprintf(stderr, "error: malformed manifest line %u\n", line_number);
            zip_discard(archive);
            close_archives(&archives);
            fclose(manifest);
            zip_error_fini(&error);
            return 1;
        }
        *tab = '\0';

        zip_path = tab + 1;
        tab = strchr(zip_path, '\t');
        if (tab == NULL) {
            fprintf(stderr, "error: malformed manifest line %u\n", line_number);
            zip_discard(archive);
            close_archives(&archives);
            fclose(manifest);
            zip_error_fini(&error);
            return 1;
        }
        *tab = '\0';

        mode_text = tab + 1;
        if (parse_mode(mode_text, &mode) < 0) {
            fprintf(stderr, "error: invalid mode '%s' on manifest line %u\n", mode_text, line_number);
            zip_discard(archive);
            close_archives(&archives);
            fclose(manifest);
            zip_error_fini(&error);
            return 1;
        }

        if (add_file(archive, source_path, zip_path, mode) < 0) {
            zip_discard(archive);
            close_archives(&archives);
            fclose(manifest);
            zip_error_fini(&error);
            return 1;
        }
    }

    if (ferror(manifest)) {
        fprintf(stderr, "error: cannot read manifest '%s': %s\n", manifest_path, strerror(errno));
        zip_discard(archive);
        close_archives(&archives);
        fclose(manifest);
        zip_error_fini(&error);
        return 1;
    }

    fclose(manifest);

    if (zip_close(archive) < 0) {
        fprintf(stderr, "error: cannot finish zip '%s': %s\n", out_path, zip_strerror(archive));
        zip_discard(archive);
        close_archives(&archives);
        zip_error_fini(&error);
        return 1;
    }

    close_archives(&archives);
    zip_error_fini(&error);
    return 0;
}
