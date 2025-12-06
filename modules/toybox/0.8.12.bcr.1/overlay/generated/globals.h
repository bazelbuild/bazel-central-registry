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

struct arp_data {
    char *hw_type;
    char *af_type_A;
    char *af_type_p;
    char *interface;

    int sockfd;
    char *device;
};

struct arping_data {
    long count;
    unsigned long time_out;
    char *iface;
    char *src_ip;

    int sockfd;
    unsigned long start, end;
    unsigned sent_at, sent_nr, rcvd_nr, brd_sent, rcvd_req, brd_rcv,
             unicast_flag;
};

struct awk_data {
  struct arg_list *f;
  struct arg_list *v;
  char *F;

  struct scanner_state {
      char *p;
      char *progstring;
      struct arg_list *prog_args;
      char *filename;
      char *line;
      size_t line_size;
      ssize_t line_len;
      int line_num;
      int ch;
      FILE *fp;
      // state includes latest token seen
      int tok;
      int tokbuiltin;
      int toktype;
      char *tokstr;
      size_t maxtok;
      size_t toklen;
      double numval;
      int error;  // Set if lexical error.
  } *scs;
  char *tokstr;
  int prevtok;

  struct compiler_globals {
    int in_print_stmt;
    int paren_level;
    int in_function_body;
    int funcnum;
    int nparms;
    int compile_error_count;
    int first_begin;
    int last_begin;
    int first_end;
    int last_end;
    int first_recrule;
    int last_recrule;
    int break_dest;
    int continue_dest;
    int stack_offset_to_fix;  // fixup stack if return in for(e in a)
    int range_pattern_num;
    int rule_type;  // tkbegin, tkend, or 0
  } cgl;

  // zvalue: the main awk value type
  // Can be number or string or both, or else map (array) or regex
  struct zvalue {
    unsigned flags;
    double num;
    union { // anonymous union not in C99; not going to fix it now.
      struct zstring *vst;
      struct zmap *map;
      regex_t *rx;
    };
  } nozvalue;   // to shut up compiler warning TODO FIXME

  struct runtime_globals {
    struct zvalue cur_arg;
    FILE *fp;           // current data file
    int narg;           // cmdline arg index
    int nfiles;         // num of cmdline data file args processed
    int eof;            // all cmdline files (incl. stdin) read
    char *recptr;
    struct zstring *zspr;      // Global to receive sprintf() string value
  } rgl;

  // Expanding sequential list
  struct zlist {
    char *base, *limit, *avail;
    size_t size;
  } globals_table,  // global symbol table
    locals_table,     // local symbol table
    func_def_table;  // function symbol table
  // runtime lists
  struct zlist literals, fields, zcode, stack;

  char *progname;

  int spec_var_limit;
  int zcode_last;
  struct zvalue *stackp;  // top of stack ptr

  char *pbuf;   // Used for number formatting in num_to_zstring()
#define RS_MAX  64
  char rs_last[RS_MAX];
  regex_t rx_rs_default, rx_rs_last;
  regex_t rx_default, rx_last, rx_printf_fmt;
#define FS_MAX  64
  char fs_last[FS_MAX];
  char one_char_fs[4];
  int nf_internal;  // should match NF
  char range_sw[64];   // FIXME TODO quick and dirty set of range switches
  int file_cnt, std_file_cnt;

  struct zfile {
    struct zfile *next;
    char *fn;
    FILE *fp;
    char mode;  // w, a, or r
    char file_or_pipe;  // 1 if file, 0 if pipe
    char is_tty, is_std_file;
    char eof;
    int ro, lim, buflen;
    char *buf;
  } *zfiles, *cfile, *zstdout;
};

struct bc_data {
  // This actually needs to be a BcVm*, but the toybox build
  // system complains if I make it so. Instead, we'll just cast.
  char *vm;

  size_t nchars;
  char *file, sig, max_ibase;
  uint16_t line_len;
};

struct bootchartd_data {
  char timestamp[32];
  long msec;
  int proc_accounting;

  pid_t pid;
};

struct brctl_data {
    int sockfd;
};

struct chsh_data {
  char *s, *R;
};

struct crond_data {
  char *c, *l;
  int loglevel_d;
  int loglevel;

  time_t crontabs_dir_mtime;
};

struct crontab_data {
  char *user;
  char *cdir;
};

struct csplit_data {
  long n;
  char *f;

  size_t indx, findx, lineno;
  char *filefmt, *prefix;
  // Variables the context checker need to track between lines
  size_t btc, tmp;
  int offset, withld, inf;
};

struct dhcp_data {
    char *iface;
    char *pidfile;
    char *script;
    long retries;
    long timeout;
    long tryagain;
    struct arg_list *req_opt;
    char *req_ip;
    struct arg_list *pkt_opt;
    char *fdn_name;
    char *hostname;
    char *vendor_cls;
};

struct dhcp6_data {
  char *interface_name, *pidfile, *script;
  long retry, timeout, errortimeout;
  char *req_ip;
  int length, state, request_length, sock, sock1, status, retval, retries;
  struct timeval tv;
  uint8_t transction_id[3];
  struct sockaddr_in6 input_socket6;
};

struct dhcpd_data {
  char *i;
  long p;
};

struct diff_data {
  long U;
  struct arg_list *L;
  char *F, *S, *new_line_format, *old_line_format, *unchanged_line_format;

  int dir_num, size, is_binary, is_symlink, differ, change, len[2], *offset[2];
  struct stat st[2];
  struct {
    char **list;
    int nr_elm;
  } dir[2];
  struct {
    FILE *fp;
    int len;
  } file[2];
  struct {
    char *name;
    int len;
  } link[2];
};

struct dumpleases_data {
    char *file;
};

struct expr_data {
  char **tok, *delete;
};

struct fdisk_data {
  long sect_sz;
  long sectors;
  long heads;
  long cylinders;
};

struct fsck_data {
  int fd_num;
  char *t_list;

  struct double_list *devices;
  char *arr_flag;
  char **arr_type;
  int negate;
  int sum_status;
  int nr_run;
  int sig_num;
  long max_nr_run;
};

struct getfattr_data {
  char *n;
};

struct getty_data {
  char *f, *l, *I, *H;
  long t;

  char *tty_name, buff[128];
  int speeds[20], sc;
  struct termios termios;
  struct utsname uts;
};

struct groupadd_data {
  long g;
  char *R;
};

struct hexdump_data {
    long s, n;

    long long len, pos, ppos;
    const char *fmt;
    unsigned int fn, bc;  // file number and byte count
    char linebuf[16];  // line buffer - serves double duty for sqeezing repeat
                       // lines and for accumulating full lines accross file
                       // boundaries if necessesary.
};

struct ip_data {
  char stats, singleline, flush, *filter_dev, gbuf[8192];
  int sockfd, connected, from_ok, route_cmd;
  int8_t addressfamily, is_addr;
};

struct ipcrm_data {
  struct arg_list *qkey;
  struct arg_list *qid;
  struct arg_list *skey;
  struct arg_list *sid;
  struct arg_list *mkey;
  struct arg_list *mid;
};

struct ipcs_data {
  int id;
};

struct klogd_data {
  long level;

  int fd;
};

struct last_data {
  char *file;

  struct arg_list *list;
};

struct lsof_data {
  struct arg_list *p;

  struct stat *sought_files;
  struct double_list *all_sockets, *files;
  int last_shown_pid, shown_header;
};

struct man_data {
  char *M, *k;

  char any, cell, ex, *f, k_done, *line, *m, **sct, **scts, **sufs;
  regex_t reg;
};

struct modprobe_data {
  struct arg_list *dirs;

  struct arg_list *probes, *dbase[256];
  char *cmdopts;
  int nudeps, symreq;
};

struct more_data {
  struct termios inf;
  int cin_fd;
};

struct route_data {
  char *A;
};

struct sh_data {
  union {
    struct {
      char *c;
    } sh;
    struct {
      char *a;
    } exec;
  };

  // keep SECONDS here: used to work around compiler limitation in run_command()
  long long SECONDS;
  char *isexec, *wcpat;
  unsigned options, jobcnt;
  int hfd, pid, bangpid, recursion;
  jmp_buf forkchild;

  // Callable function array
  struct sh_function {
    char *name;
    struct sh_pipeline {  // pipeline segments: linked list of arg w/metadata
      struct sh_pipeline *next, *prev, *end;
      int count, here, type;
      long lineno;
      struct sh_arg {
        char **v;
        int c;
      } arg[1];
    } *pipeline;
    unsigned long refcount;
  } **functions;
  long funcslen;

  // runtime function call stack. TT.ff is current function, returns to ->next
  struct sh_fcall {
    struct sh_fcall *next, *prev;

    // Each level has its own local variables, root (TT.ff->prev) is globals
    struct sh_vars {
      long flags;
      char *str;
    } *vars;
    long varslen, varscap, shift, lineno;

    struct sh_function *function;
    FILE *source;
    char *ifs, *name, *_;
    struct sh_pipeline *pl;
    struct sh_arg arg;
    struct arg_list *delete;

    // Runtime stack of nested if/else/fi and for/do/done contexts.
    struct sh_blockstack {
      struct sh_blockstack *next;
      struct sh_pipeline *start, *middle;
      struct sh_process *pp;       // list of processes piping in to us
      int run, loop, *urd, pout, pipe;
      struct sh_arg farg;          // for/select arg stack, case wildcard deck
      struct arg_list *fdelete;    // farg's cleanup list
      char *fvar;                  // for/select's iteration variable name
    } *blk;

// TODO ctrl-Z suspend should stop script
    struct sh_process {
      struct sh_process *next, *prev; // | && ||
      struct arg_list *delete;   // expanded strings
      // undo redirects, a=b at start, child PID, exit status, has !, job #
      int *urd, envlen, pid, exit, flags, job, dash, refcount;
      long long when; // when job backgrounded/suspended
      struct sh_arg *raw, arg;
    } *pp;
  } *ff;

  // job list, command line for $*, scratch space for do_wildcard_files()
  struct sh_arg jobs, *wcdeck;
};

struct strace_data {
  long s, p;

  char ioctl[32], *fmt;
  long regs[256/sizeof(long)], syscall;
  pid_t pid;
  int arg;
};

struct stty_data {
  char *F;

  int fd, col;
  unsigned output_cols;
};

struct sulogin_data {
  long timeout;
  struct termios crntio;
};

struct syslogd_data {
  char *socket;
  char *config_file;
  char *unix_socket;
  char *logfile;
  long interval;
  long rot_size;
  long rot_count;
  char *remote_log;
  long log_prio;

  struct unsocks *lsocks;  // list of listen sockets
  struct logfile *lfiles;  // list of write logfiles
  int sigfd[2];
};

struct tcpsvd_data {
  char *l, *u, *C;
  long b, c;

  int maxc;
  int count_all;
  int udp;
};

struct telnet_data {
  int sock;
  char buf[2048]; // Half sizeof(toybuf) allows a buffer full of IACs.
  struct termios old_term;
  struct termios raw_term;
  uint8_t mode;
  int echo, sga;
  int state, request;
};

struct telnetd_data {
    char *login_path;
    char *issue_path;
    int port;
    char *host_addr;
    long w_sec;

    int gmax_fd;
    pid_t fork_pid;
};

struct tftp_data {
  char *local_file;
  char *remote_file;
  long block_size;

  struct sockaddr_storage inaddr;
  int af;
};

struct tftpd_data {
  char *user;

  long sfd;
  struct passwd *pw;
};

struct tr_data {
  short *map;
  int len1, len2;
};

struct traceroute_data {
  long max_ttl;
  long port;
  long ttl_probes;
  char *src_ip;
  long tos;
  long wait_time;
  struct arg_list *loose_source;
  long pause_time;
  long first_ttl;
  char *iface;

  uint32_t gw_list[9];
  int recv_sock;
  int snd_sock;
  unsigned msg_len;
  char *packet;
  uint32_t ident;
  int istraceroute6;
};

struct useradd_data {
  char *dir;
  char *gecos;
  char *shell;
  char *u_grp;
  long uid;

  long gid;
};

struct vi_data {
  char *c, *s;

  char *filename;
  int vi_mode, tabstop, list, cur_col, cur_row, scr_row, drawn_row, drawn_col,
      count0, count1, vi_mov_flag;
  unsigned screen_height, screen_width;
  char vi_reg, *last_search;
  struct str_line {
    int alloc, len;
    char *data;
  } *il;
  size_t screen, cursor; //offsets
  //yank buffer
  struct yank_buf {
    char reg;
    int alloc;
    char *data;
  } yank;

  size_t filesize;
// mem_block contains RO data that is either original file as mmap
// or heap allocated inserted data
  struct block_list {
    struct block_list *next, *prev;
    struct mem_block {
      size_t size, len;
      enum alloc_flag {
        MMAP,  //can be munmap() before exit()
        HEAP,  //can be free() before exit()
        STACK, //global or stack perhaps toybuf
      } alloc;
      const char *data;
    } *node;
  } *text;

// slices do not contain actual allocated data but slices of data in mem_block
// when file is first opened it has only one slice.
// after inserting data into middle new mem_block is allocated for insert data
// and 3 slices are created, where first and last slice are pointing to original
// mem_block with offsets, and middle slice is pointing to newly allocated block
// When deleting, data is not freed but mem_blocks are sliced more such way that
// deleted data left between 2 slices
  struct slice_list {
    struct slice_list *next, *prev;
    struct slice {
      size_t len;
      const char *data;
    } *node;
  } *slices;
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
	struct arp_data arp;
	struct arping_data arping;
	struct awk_data awk;
	struct bc_data bc;
	struct bootchartd_data bootchartd;
	struct brctl_data brctl;
	struct chsh_data chsh;
	struct crond_data crond;
	struct crontab_data crontab;
	struct csplit_data csplit;
	struct dhcp_data dhcp;
	struct dhcp6_data dhcp6;
	struct dhcpd_data dhcpd;
	struct diff_data diff;
	struct dumpleases_data dumpleases;
	struct expr_data expr;
	struct fdisk_data fdisk;
	struct fsck_data fsck;
	struct getfattr_data getfattr;
	struct getty_data getty;
	struct groupadd_data groupadd;
	struct hexdump_data hexdump;
	struct ip_data ip;
	struct ipcrm_data ipcrm;
	struct ipcs_data ipcs;
	struct klogd_data klogd;
	struct last_data last;
	struct lsof_data lsof;
	struct man_data man;
	struct modprobe_data modprobe;
	struct more_data more;
	struct route_data route;
	struct sh_data sh;
	struct strace_data strace;
	struct stty_data stty;
	struct sulogin_data sulogin;
	struct syslogd_data syslogd;
	struct tcpsvd_data tcpsvd;
	struct telnet_data telnet;
	struct telnetd_data telnetd;
	struct tftp_data tftp;
	struct tftpd_data tftpd;
	struct tr_data tr;
	struct traceroute_data traceroute;
	struct useradd_data useradd;
	struct vi_data vi;
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
