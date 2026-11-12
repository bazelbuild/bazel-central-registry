/* MSVC compatibility shim for gawk — force-included on MSVC builds via
   `/FI msvc_shim.h`. Upstream gawk doesn't officially support MSVC; this
   header patches the rough edges so the base interpreter compiles
   without touching most upstream source files. The one exception is a
   single-line patch to `awk.h`'s `__STDC__` hard-error check
   (`patches/awk_h_msvc_stdc_exempt.patch`), which lets us avoid having
   to predefine `__STDC__=1` and then unwind MSVC's POSIX-name hiding. */

#ifndef GAWK_MSVC_SHIM_H
#define GAWK_MSVC_SHIM_H

#ifdef _MSC_VER

/* `gawkapi.h:28-36` documents that consumers MUST `#include` <stdio.h>,
   <stddef.h>, <string.h>, <sys/types.h>, <sys/stat.h> before including
   `gawkapi.h`. On Linux/macOS `awk.h` covers that for us, but the MSVC
   preprocess order can land `gawkapi.h` parsing before `awk.h`'s own
   `#include <sys/stat.h>` runs, leaving `struct stat` undefined at the
   field declaration `awk_input_buf_t::sbuf`. Pull them in here so
   `gawkapi.h` always sees them. */
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

/* Note: we deliberately do NOT predefine `__STDC__=1` (the upstream
   `awk.h` `__STDC__` hard-error is bypassed by
   `patches/awk_h_msvc_stdc_exempt.patch` instead). That keeps MSVC's
   `<sys/stat.h>` exposing its POSIX-name `struct stat` natively, so no
   `#define stat _stat` aliasing is needed here. */

/* `ssize_t` — POSIX type missing from MSVC's standard headers. `gawkapi.h`
   uses it (line 201) without including a definition; provide one. */
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;

/* `off_t` — POSIX integer type. MSVC's `<sys/types.h>` provides `_off_t`,
   but only exposes the POSIX `off_t` alias under specific feature-test
   macros. Provide a guarded fallback. */
#ifndef _OFF_T_DEFINED
typedef long off_t;
#define _OFF_T_DEFINED
#endif

/* `<fcntl.h>` — pulls in `O_RDONLY`, `O_WRONLY`, etc., which gawk uses in
   `debug.c` and `io.c`. MSVC ships the header; we just need to include
   it ahead of any conditional gates that decide whether to expect it. */
#include <fcntl.h>

/* MSVC's CRT exposes POSIX low-level I/O / process / pipe routines only
   under underscore-prefixed names. Alias the POSIX-form names back so
   source-level call sites in `awkgram.y` / `io.c` / `builtin.c`
   resolve without touching upstream files. None of MSVC's headers
   define the POSIX-form names (deprecated and removed in modern UCRT
   builds), so plain `#define` without `#ifndef` guards is safe.
     `<io.h>`      — `close`, `read`, `write`, `lseek`, `dup`, etc.
     `<process.h>` — `spawnl`, `_cwait`, `P_NOWAIT`. `_cwait` already
                     starts with an underscore so it's called as-is.
     `<stdio.h>`   — `popen`, `pclose` (UCRT keeps these only as `_`-
                     prefixed too). */
#include <io.h>
#include <process.h>
#define close _close
#define read _read
#define write _write
#define lseek _lseek
#define dup _dup
#define dup2 _dup2
#define isatty _isatty
#define fileno _fileno
#define unlink _unlink
#define getpid _getpid
#define spawnl _spawnl
#define spawnv _spawnv
#define P_NOWAIT _P_NOWAIT
#define popen _popen
#define pclose _pclose

/* `pipe()` — POSIX takes `int pipefd[2]`; MSVC's `_pipe` takes
   `(int *fds, unsigned size, int textmode)`. Provide a 2-arg shim that
   forwards to `_pipe` with sane defaults (4 KiB buffer, binary mode —
   gawk handles text-mode translation itself via `os_setbinmode`). */
static __inline int gawk_msvc_pipe_shim(int fds[2]) {
    return _pipe(fds, 4096, _O_BINARY);
}
#ifndef pipe
#define pipe(fds) gawk_msvc_pipe_shim(fds)
#endif

/* `pid_t` — POSIX type used by `wait_any`'s `pid` local and various
   helpers. MSVC has no `<sys/types.h>` `pid_t`; `_cwait` returns
   `intptr_t`, but for compatibility with the source-level
   declarations a plain `int` matches MinGW's effective type here. */
#ifndef _PID_T_DEFINED
typedef int pid_t;
#define _PID_T_DEFINED
#endif

/* `mode_t` — POSIX type used by `io.c:file_can_timeout`'s parameter
   list. MSVC's `<sys/stat.h>` defines `_mode_t` as `unsigned short`
   but does NOT define the POSIX `mode_t` alias. */
#ifndef _MODE_T_
typedef unsigned short mode_t;
#define _MODE_T_
#endif

/* `kill()` / `SIGKILL` — POSIX. Used in `io.c:two_way_open` on the
   error path after pipe setup fails, to terminate the spawned child.
   MSVC has neither. Provide a no-op `kill()` and a dummy `SIGKILL`
   constant so the code compiles; the consequence is that a failed
   `|&` setup may leak the child process, which matches what MinGW
   does (its `kill()` is also documented as unreliable on Windows). */
#ifndef SIGKILL
#define SIGKILL 9
#endif
static __inline int kill(pid_t _pid, int _sig) {
    (void)_pid;
    (void)_sig;
    return 0;
}

/* `W*` wait-status macros — POSIX puts these in `<sys/wait.h>`. MSVC
   has no `<sys/wait.h>`. `builtin.c:sanitize_exit_status` and
   `io.c:wait_any` reference them; gawk's MinGW path emulates them
   over Win32's exit-status convention (top two bits set indicates a
   crashing exception). We mirror that here. `w32_status_to_termsig`
   is a real function in `pc/gawkmisc.pc` which MSVC doesn't compile;
   substitute a trivial inline that returns a SIGTERM-equivalent for
   simplicity (the script-visible value is `WTERMSIG(status) + 256`
   which is informational only). */
#ifndef WEXITSTATUS
#define WEXITSTATUS(stv) (((unsigned)(stv)) & ~0xC0000000)
#endif
#ifndef WIFEXITED
#define WIFEXITED(stv)   ((((unsigned)(stv)) & 0xC0000000) == 0)
#endif
#ifndef WIFSIGNALED
#define WIFSIGNALED(stv) ((((unsigned)(stv)) & 0xC0000000) == 0xC0000000)
#endif
#ifndef WTERMSIG
#define WTERMSIG(stv)    (((unsigned)(stv)) & 0xFF)
#endif

/* Identity (`getuid`, `geteuid`, `getgid`, `getegid`, `getpgrp`,
   `getppid`) — gawk's `main.c:load_procinfo` calls these unconditionally
   to populate `PROCINFO[]`. MinGW provides them via `pc/getid.c`; MSVC
   has neither. Windows has no notion of POSIX uid/gid, so returning 0
   matches MinGW's pc/getid stubs (which return 0/1 sentinels). Defining
   `GETPGRP_VOID` selects the no-arg call form so our stub signature
   matches. */
#define GETPGRP_VOID 1
static __inline unsigned int getuid(void)  { return 0; }
static __inline unsigned int geteuid(void) { return 0; }
static __inline unsigned int getgid(void)  { return 0; }
static __inline unsigned int getegid(void) { return 0; }
static __inline int getpgrp(void)          { return 0; }
static __inline int getppid(void)          { return 1; }

/* `setenv` / `unsetenv` — POSIX. MSVC has `_putenv_s` (in `<stdlib.h>`)
   but not the POSIX names; gawk's `replace.c` includes
   `missing_d/timegm.c` which calls `setenv`/`unsetenv`, and `debug.c` /
   `str_array.c` call them too. The `overwrite` arg to POSIX `setenv` is
   ignored here — `_putenv_s` always overwrites, which matches the
   common case (gawk callers all pass 1 anyway). */
#include <stdlib.h>
static __inline int setenv(const char *name, const char *value, int overwrite) {
    (void)overwrite;
    return _putenv_s(name, value);
}
static __inline int unsetenv(const char *name) {
    return _putenv_s(name, "");
}

/* `quote_cmd` — defined in `pc/popen.c` under `__MINGW32__`, called
   from `io.c`'s MinGW path (`gawk_popen` / `two_way_open`) which MSVC
   now follows. cmd.exe strips the outermost quote pair from its
   command-line argument, so wrapping the command in `"…"` lets a
   command with embedded spaces / inner quotes survive the shell. The
   returned buffer is `efree()`d by the caller. */
#include <string.h>
static __inline char *quote_cmd(const char *_cmd) {
    size_t _n = strlen(_cmd);
    char *_q = (char *)malloc(_n + 3);
    if (_q == NULL) return NULL;
    _q[0] = '"';
    memcpy(_q + 1, _cmd, _n);
    _q[_n + 1] = '"';
    _q[_n + 2] = '\0';
    return _q;
}

/* `S_IFMT` / `S_IFREG` / `S_IFCHR` / `S_IFDIR` / `S_IFIFO` — POSIX
   stat-mode flags. MSVC's `<sys/stat.h>` always defines the `_S_IF*`
   variants; the POSIX-named macros are exposed by default but may be
   missing under some `_CRT_*` feature-test configurations. Alias them
   if absent so `posix/gawkmisc.c` compiles. */
#ifndef S_IFMT
#define S_IFMT _S_IFMT
#endif
#ifndef S_IFREG
#define S_IFREG _S_IFREG
#endif
#ifndef S_IFCHR
#define S_IFCHR _S_IFCHR
#endif
#ifndef S_IFDIR
#define S_IFDIR _S_IFDIR
#endif
#ifndef S_IFIFO
#define S_IFIFO _S_IFIFO
#endif
/* `S_IFBLK` — POSIX block-device flag. Windows has no concept of block
   devices, and MSVC's `<sys/stat.h>` doesn't define `_S_IFBLK`. Pick a
   value that doesn't collide with the existing `_S_IF*` constants
   (0x1000, 0x2000, 0x4000, 0x8000); 0x3000 is unused. Real-file
   `st_mode` values will never match, which is the correct semantics. */
#ifndef S_IFBLK
#define S_IFBLK 0x3000
#endif
#ifndef S_ISREG
#define S_ISREG(m) (((m) & S_IFMT) == S_IFREG)
#endif
#ifndef S_ISDIR
#define S_ISDIR(m) (((m) & S_IFMT) == S_IFDIR)
#endif
#ifndef S_ISCHR
#define S_ISCHR(m) (((m) & S_IFMT) == S_IFCHR)
#endif

/* `fcntl()` / `F_GETFD` / `F_SETFD` — POSIX file-descriptor control.
   MSVC has no equivalent (FD inheritance on Windows is set via
   `SetHandleInformation` at handle-creation time). gawk's only use is
   `os_close_on_exec()` in `posix/gawkmisc.c`; a no-op stub keeps the
   code compiling and produces benign behavior (the FD just stays
   inherited, which matches Windows defaults anyway). */
#ifndef F_GETFD
#define F_GETFD 1
#endif
#ifndef F_SETFD
#define F_SETFD 2
#endif
#ifndef FD_CLOEXEC
#define FD_CLOEXEC 1
#endif
static __inline int fcntl(int _fd, int _cmd, ...) {
    (void)_fd;
    (void)_cmd;
    return 0;
}

/* `support/regex.h:671` declares
       regmatch_t __pmatch[_Restrict_arr_]
   using C99 array-restrict syntax. MSVC's C parser rejects this even
   with `/std:c11`. Pre-empting the `#ifndef _Restrict_arr_` guard with
   an empty definition keeps the syntax simple. */
#ifndef _Restrict_arr_
#define _Restrict_arr_
#endif

#endif /* _MSC_VER */

#endif /* GAWK_MSVC_SHIM_H */
