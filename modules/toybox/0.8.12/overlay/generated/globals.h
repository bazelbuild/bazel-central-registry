struct dmesg_data {
  long n, s;

  int use_color;
  time_t tea;
};

struct gzip_data {
  int level;
};

struct hostname_data {
  char *F;
};

struct killall_data {
  char *s;

  int signum;
  pid_t cur_pid;
  char **names;
  short *err;
  struct int_list { struct int_list *next; int val; } *pids;
};

struct md5sum_data {
  int sawline;
};

struct mknod_data {
  char *Z, *m;
};

struct mktemp_data {
  char *p, *tmpdir;
};

struct mount_data {
  struct arg_list *o;
  char *t, *O;

  unsigned long flags;
  char *opts;
  int okuser;
};

struct pidof_data {
  char *o;
};

struct seq_data {
  char *s, *f;

  int precision, buflen;
};

struct su_data {
  char *s, *c;
};

struct umount_data {
  struct arg_list *t;

  char *types;
};

struct ftpget_data {
  char *u, *p, *P;

  int fd;
};

struct host_data {
  char *t;

  char **nsname;
  unsigned nslen;
};

struct ifconfig_data {
  int sockfd;
};

struct microcom_data {
  long s;

  int fd, stok;
  struct termios old_stdin, old_fd;
};

struct netcat_data {
  char *f, *s, *o, *O;
  long q, p, W, w;

  unsigned ofd, olast, opos, ocount[2];
  char obuf[16];
};

struct netstat_data {
  struct num_cache *inodes;
  int wpad;
};

struct ping_data {
  char *I;
  long w, W, i, s, c, t, m;

  struct sockaddr *sa;
  int sock;
  unsigned long sent, recv, fugit, min, max;
};

struct sntp_data {
  long r, t;
  char *p, *m, *M;
};

struct tunctl_data {
  char *u;
};

struct wget_data {
  char *p, *O;
  long max_redirect;

  int sock, https;
  char *url;
#if CFG_WGET_LIBTLS
  struct tls *tls;
#elif CFG_TOYBOX_LIBCRYPTO
  struct ssl_ctx_st *ctx;
  struct ssl_st *ssl;
#endif
};

struct base64_data {
  long w;

  unsigned total;
  unsigned n;  // number of bits used in encoding. 5 for base32, 6 for base64
  unsigned align;  // number of bits to align to
};

struct blkdiscard_data {
  long o, l;
};

struct blkid_data {
  struct arg_list *s;
  char *o;
};

struct blockdev_data {
  long setra, setbsz;
};

struct chrt_data {
  long p;
};

struct count_data {
  unsigned long long size, start;
  unsigned tick, *slice;
};

struct devmem_data {
  char *f;
};

struct dos2unix_data {
  char *tempfile;
};

struct fallocate_data {
  long o, l;
};

struct fmt_data {
  long width;

  int level, pos;
};

struct free_data {
  unsigned bits;
  unsigned long long units;
  char *buf;
};

struct getopt_data {
  struct arg_list *l;
  char *o, *n;
};

struct gpiodetect_data {
  struct double_list *chips;
  int chip_count;
};

struct hexedit_data {
  char *data, *search, keybuf[16], input[80];
  long long len, base, pos;
  int numlen, undo, undolen, mode;
  unsigned rows, cols;
};

struct hwclock_data {
  char *f;
};

struct i2cdetect_data {
  long F;
};

struct ionice_data {
  long p, n, c;
};

struct login_data {
  char *h, *f;

  int login_timeout, login_fail_timeout;
};

struct losetup_data {
  char *j;
  long o, S;

  int openflags;
  dev_t jdev;
  ino_t jino;
  char *dir;
};

struct lsattr_data {
  long v, p;

  unsigned add, rm, set;
  // !add and !rm tell us whether they were used, but `chattr =` is meaningful.
  int have_set;
};

struct lsusb_data {
  char *i;
  long x, n;

  void *ids, *class;
  int count;
};

struct makedevs_data {
  char *d;
};

struct mix_data {
   long r, l;
   char *d, *c;
};

struct mkpasswd_data {
  long P;
  char *m, *S;
};

struct mkswap_data {
  char *L;
};

struct modinfo_data {
  char *F, *k, *b;

  long mod;
  int count;
};

struct nbd_client_data {
  long b;

  int nbd;
};

struct nsenter_data {
  char *UupnmiC[7];
  long t;
};

struct oneit_data {
  char *c;
};

struct openvt_data {
  long c;
};

struct pwgen_data {
  char *r;
};

struct readelf_data {
  char *x, *p;

  char *elf, *shstrtab, *f;
  unsigned long long shoff, phoff, size, shstrtabsz;
  int bits, endian, shnum, shentsize, phentsize;
};

struct realpath_data {
  char *R, *relative_base;
};

struct reboot_data {
  char *d;
};

struct rtcwake_data {
  long t, s;
  char *m, *d;
};

struct setfattr_data {
  char *x, *v, *n;
};

struct setsid_data {
  long c;
};

struct sha3sum_data {
  long a;
  unsigned long long rc[24];
};

struct shred_data {
  long o, n, s;
};

struct shuf_data {
  long n;

  char **lines;
  long count;
};

struct stat_data {
  char *c;

  union {
    struct stat st;
    struct statfs sf;
  } stat;
  char *file, *pattern;
  int patlen;
};

struct swapon_data {
  long p;
};

struct switch_root_data {
  char *c;

  struct stat new;
  dev_t rootdev;
};

struct tac_data {
  struct double_list *dl;
};

struct timeout_data {
  char *s, *k;

  struct pollfd pfd;
  sigjmp_buf sj;
  int fds[2], pid, rc;
};

struct truncate_data {
  char *s;

  long long size;
  int type;
};

struct uclampset_data {
  long M, m, p;
};

struct watch_data {
  int n;

  pid_t pid, oldpid;
};

struct watchdog_data {
  long T, t;

  int fd;
};

struct xxd_data {
  long s, g, o, l, c;
};

struct basename_data {
  char *s;
};

struct cal_data {
  struct tm *now;
};

struct chgrp_data {
  uid_t owner;
  gid_t group;
  char *owner_name, *group_name;
  int symfollow;
};

struct chmod_data {
  char *mode;
};

struct cmp_data {
  long n;

  int fd;
  char *name;
};

struct cp_data {
  union {
    // install's options
    struct {
      char *g, *o, *m, *t;
    } i;
    // cp's options
    struct {
      char *t, *preserve;
    } c;
  };

  char *destname;
  struct stat top;
  int (*callback)(struct dirtree *try);
  uid_t uid;
  gid_t gid;
  int pflags;
};

struct cpio_data {
  char *F, *H, *R;
};

struct cut_data {
  char *d, *O;
  struct arg_list *select[5]; // we treat them the same, so loop through

  unsigned line;
  int pairs;
  regex_t reg;
};

struct date_data {
  char *s, *r, *I, *D, *d;

  unsigned nano;
};

struct dd_data {
  // Display fields
  int show_xfer, show_records;
  unsigned long long bytes, in_full, in_part, out_full, out_part, start;
};

struct df_data {
  struct arg_list *t;

  int units, width[6];
};

struct du_data {
  long d;

  unsigned long depth, total;
  dev_t st_dev;
  void *inodes;
};

struct env_data {
  struct arg_list *u;
  char *e;
};

struct expand_data {
  struct arg_list *t;

  unsigned tabcount, *tab;
};

struct file_data {
  int max_name_len;
  off_t len;
};

struct find_data {
  char **filter;
  struct double_list *argdata;
  int topdir, xdev, depth;
  time_t now;
  long max_bytes;
  char *start;
};

struct fold_data {
  long w;
};

struct grep_data {
  long m, A, B, C;
  struct arg_list *f, *e, *M, *S, *exclude_dir;
  char *color;

  char *purple, *cyan, *red, *green, *grey;
  struct double_list *reg;
  int found, tried, delim;
  struct arg_list **fixed;
};

struct head_data {
  long c, n;

  int file_no;
};

struct iconv_data {
  char *f, *t;

  void *ic;
};

struct id_data {
  int is_groups;
};

struct kill_data {
  char *s;
  struct arg_list *o;
};

struct ln_data {
  char *t;
};

struct logger_data {
  char *p, *t;

  int priority;
};

struct ls_data {
  long w, l, block_size;
  char *color, *sort;

  struct dirtree *files, *singledir;
  unsigned screen_width;
  int nl_title;
  char *escmore;
};

struct mkdir_data {
  char *m, *Z;
};

struct mkfifo_data {
  char *m, *Z;

  mode_t mode;
};

struct nice_data {
  long n;
};

struct nl_data {
  char *s, *n, *b;
  long w, l, v;

  // Count of consecutive blank lines for -l has to persist between files
  long lcount, slen;
};

struct od_data {
  struct arg_list *t;
  char *A;
  long N, w, j;

  int address_idx;
  unsigned types, leftover, star;
  char *buf; // Points to buffers[0] or buffers[1].
  char *bufs[2]; // Used to detect duplicate lines.
  off_t pos;
};

struct paste_data {
  char *d;

  int files;
};

struct patch_data {
  char *i, *d;
  long v, p, g, F;

  void *current_hunk;
  long oldline, oldlen, newline, newlen, linenum, outnum;
  int context, state, filein, fileout, filepatch, hunknum;
  char *tempname;
};

struct ps_data {
  union {
    struct {
      struct arg_list *G, *g, *U, *u, *t, *s, *p, *O, *o, *P, *k;
    } ps;
    struct {
      long n, m, d, s;
      struct arg_list *u, *p, *o, *k, *O;
    } top;
    struct {
      char *L;
      struct arg_list *G, *g, *P, *s, *t, *U, *u;
      char *d;

      void *regexes, *snapshot;
      int signal;
      pid_t self, match;
    } pgrep;
  };

  struct ps_ptr_len {
    void *ptr;
    long len;
  } gg, GG, pp, PP, ss, tt, uu, UU;
  struct dirtree *threadparent;
  unsigned width, height, scroll;
  dev_t tty;
  void *fields, *kfields;
  long long ticks, bits, time;
  int kcount, forcek, sortpos, pidlen;
  int (*match_process)(long long *slot);
  void (*show_process)(void *tb);
};

struct renice_data {
  long n;
};

struct sed_data {
  char *i;
  struct arg_list *f, *e;

  // processed pattern list
  struct double_list *pattern;

  char *nextline, *remember, *tarxform;
  void *restart, *lastregex;
  long nextlen, rememberlen, count;
  int fdout, noeol;
  unsigned xx, tarxlen, xflags;
  char delim, xftype;
};

struct sort_data {
  char *t;
  struct arg_list *k;
  char *o, *T, S;

  void *key_list;
  unsigned linecount;
  char **lines, *name;
};

struct split_data {
  long n, l, b, a;

  char *outfile;
};

struct strings_data {
  long n;
  char *t;
};

struct tail_data {
  long n, c;
  char *s;

  int file_no, last_fd, ss;
  struct xnotify *not;
  struct {
    char *path;
    int fd;
    struct dev_ino di;
  } *F;
};

struct tar_data {
  char *f, *C, *I;
  struct arg_list *T, *X, *xform;
  long strip;
  char *to_command, *owner, *group, *mtime, *mode, *sort;
  struct arg_list *exclude;

  struct double_list *incl, *excl, *seen;
  struct string_list *dirs;
  char *cwd, **xfsed;
  int fd, ouid, ggid, hlc, warn, sparselen, pid, xfpipe[2];
  struct dev_ino archive_di;
  long long *sparse;
  time_t mtt;

  // hardlinks seen so far (hlc many)
  struct {
    char *arg;
    struct dev_ino di;
  } *hlx;

  // Parsed information about a tar header.
  struct tar_header {
    char *name, *link_target, *uname, *gname;
    long long size, ssize, oldsparse;
    uid_t uid;
    gid_t gid;
    mode_t mode;
    time_t mtime;
    dev_t device;
  } hdr;
};

struct tee_data {
  void *outputs;
  int out;
};

struct touch_data {
  char *t, *r, *d;
};

struct ulimit_data {
  long P;
};

struct uniq_data {
  long w, s, f;

  long repeats;
};

struct uudecode_data {
  char *o;
};

struct wc_data {
  unsigned long totals[5];
};

struct xargs_data {
  long s, n, P;
  char *E;

  long entries, bytes, np;
  char delim;
  FILE *tty;
};
extern union global_union {
	struct dmesg_data dmesg;
	struct gzip_data gzip;
	struct hostname_data hostname;
	struct killall_data killall;
	struct md5sum_data md5sum;
	struct mknod_data mknod;
	struct mktemp_data mktemp;
	struct mount_data mount;
	struct pidof_data pidof;
	struct seq_data seq;
	struct su_data su;
	struct umount_data umount;
	struct ftpget_data ftpget;
	struct host_data host;
	struct ifconfig_data ifconfig;
	struct microcom_data microcom;
	struct netcat_data netcat;
	struct netstat_data netstat;
	struct ping_data ping;
	struct sntp_data sntp;
	struct tunctl_data tunctl;
	struct wget_data wget;
	struct base64_data base64;
	struct blkdiscard_data blkdiscard;
	struct blkid_data blkid;
	struct blockdev_data blockdev;
	struct chrt_data chrt;
	struct count_data count;
	struct devmem_data devmem;
	struct dos2unix_data dos2unix;
	struct fallocate_data fallocate;
	struct fmt_data fmt;
	struct free_data free;
	struct getopt_data getopt;
	struct gpiodetect_data gpiodetect;
	struct hexedit_data hexedit;
	struct hwclock_data hwclock;
	struct i2cdetect_data i2cdetect;
	struct ionice_data ionice;
	struct login_data login;
	struct losetup_data losetup;
	struct lsattr_data lsattr;
	struct lsusb_data lsusb;
	struct makedevs_data makedevs;
	struct mix_data mix;
	struct mkpasswd_data mkpasswd;
	struct mkswap_data mkswap;
	struct modinfo_data modinfo;
	struct nbd_client_data nbd_client;
	struct nsenter_data nsenter;
	struct oneit_data oneit;
	struct openvt_data openvt;
	struct pwgen_data pwgen;
	struct readelf_data readelf;
	struct realpath_data realpath;
	struct reboot_data reboot;
	struct rtcwake_data rtcwake;
	struct setfattr_data setfattr;
	struct setsid_data setsid;
	struct sha3sum_data sha3sum;
	struct shred_data shred;
	struct shuf_data shuf;
	struct stat_data stat;
	struct swapon_data swapon;
	struct switch_root_data switch_root;
	struct tac_data tac;
	struct timeout_data timeout;
	struct truncate_data truncate;
	struct uclampset_data uclampset;
	struct watch_data watch;
	struct watchdog_data watchdog;
	struct xxd_data xxd;
	struct basename_data basename;
	struct cal_data cal;
	struct chgrp_data chgrp;
	struct chmod_data chmod;
	struct cmp_data cmp;
	struct cp_data cp;
	struct cpio_data cpio;
	struct cut_data cut;
	struct date_data date;
	struct dd_data dd;
	struct df_data df;
	struct du_data du;
	struct env_data env;
	struct expand_data expand;
	struct file_data file;
	struct find_data find;
	struct fold_data fold;
	struct grep_data grep;
	struct head_data head;
	struct iconv_data iconv;
	struct id_data id;
	struct kill_data kill;
	struct ln_data ln;
	struct logger_data logger;
	struct ls_data ls;
	struct mkdir_data mkdir;
	struct mkfifo_data mkfifo;
	struct nice_data nice;
	struct nl_data nl;
	struct od_data od;
	struct paste_data paste;
	struct patch_data patch;
	struct ps_data ps;
	struct renice_data renice;
	struct sed_data sed;
	struct sort_data sort;
	struct split_data split;
	struct strings_data strings;
	struct tail_data tail;
	struct tar_data tar;
	struct tee_data tee;
	struct touch_data touch;
	struct ulimit_data ulimit;
	struct uniq_data uniq;
	struct uudecode_data uudecode;
	struct wc_data wc;
	struct xargs_data xargs;
} this;
