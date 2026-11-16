/* Linux-PAM's Linux/glibc configuration, including kernel audit support. */
#define ENABLE_NLS 1
#define HAVE_BINDTEXTDOMAIN 1
#define HAVE_CLOSE_RANGE 1
#define HAVE_EXPLICIT_BZERO 1
#define HAVE_GETGRGID_R 1
#define HAVE_GETGRNAM_R 1
#define HAVE_GETGROUPLIST 1
#define HAVE_GETPWNAM_R 1
#define HAVE_GETPWUID_R 1
#define HAVE_GETRANDOM 1
#define HAVE_GETSPNAM_R 1
#define HAVE_LIBAUDIT 1
#define HAVE_SYS_RANDOM_H 1
#define LOCALEDIR "/usr/share/locale"
#define PACKAGE "Linux-PAM"
#define SYSCONFDIR "/etc"
#define UNUSED __attribute__((__unused__))

#ifndef DEFAULT_MODULE_PATH
#if defined(__aarch64__)
#define DEFAULT_MODULE_PATH "/usr/lib/aarch64-linux-gnu/security/"
#elif defined(__x86_64__)
#define DEFAULT_MODULE_PATH "/usr/lib/x86_64-linux-gnu/security/"
#else
#define DEFAULT_MODULE_PATH "/usr/lib/security/"
#endif
#endif
