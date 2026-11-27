/* Bazel: The signames.h written by support/mksignames when cross-compiling.
   The signal names are determined at runtime by support/signames.c. */

/* A translation list so we can be polite to our users. */
extern char *signal_names[];

extern void initialize_signames (void);
