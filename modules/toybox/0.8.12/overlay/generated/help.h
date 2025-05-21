#define HELP_toybox_force_nommu "When using musl-libc on a nommu system, you'll need to say \"y\" here\nunless you used the patch in the mcm-buildall.sh script. You can also\nsay \"y\" here to test the nommu codepaths on an mmu system.\n\nA nommu system can't use fork(), it can only vfork() which suspends\nthe parent until the child calls exec() or exits. When a program\nneeds a second instance of itself to run specific code at the same\ntime as the parent, it must use a more complicated approach (such as\nexec(\"/proc/self/exe\") then pass data to the new child through a pipe)\nwhich is larger and slower, especially for things like toysh subshells\nthat need to duplicate a lot of internal state in the child process\nfork() gives you for free.\n\nLibraries like uclibc omit fork() on nommu systems, allowing\ncompile-time probes to select which codepath to use. But musl\nintentionally includes a broken version of fork() that always returns\n-ENOSYS on nommu systems, and goes out of its way to prevent any\ncross-compile compatible compile-time probes for a nommu system.\n(It doesn't even #define __MUSL__ in features.h.) Musl does this\ndespite the fact that a nommu system can't even run standard ELF\nbinaries (requiring specially packaged executables) because it wants\nto force every program to either include all nommu code in every\ninstance ever built, or drop nommu support altogether.\n\nBuilding a scripts/mcm-buildall.sh toolchain patches musl to fix this."

#define HELP_toybox_uid_usr "When commands like useradd/groupadd allocate user IDs, start here."

#define HELP_toybox_uid_sys "When commands like useradd/groupadd allocate system IDs, start here."

#define HELP_toybox_debug "Enable extra checks for debugging purposes. All of them catch\nthings that can only go wrong at development time, not runtime."

#define HELP_toybox_norecurse "When one toybox command calls another, usually it just calls the new\ncommand's main() function rather than searching the $PATH and calling\nexec on another file (which is much slower).\n\nThis disables that optimization, so toybox will run external commands\n       even when it has a built-in version of that command. This requires\n       toybox symlinks to be installed in the $PATH, or re-invoking the\n       \"toybox\" multiplexer command by name."

#define HELP_toybox_free "When a program exits, the operating system will clean up after it\n(free memory, close files, etc). To save size, toybox usually relies\non this behavior. If you're running toybox under a debugger or\nwithout a real OS (ala newlib+libgloss), enable this to make toybox\nclean up after itself."

#define HELP_toybox_zhelp "Compress help with gzip -9, deflating when displayed. This makes the\nbinary smaller but can increase runtime memory usage."

#define HELP_toybox_help_dashdash "Support --help argument in all commands, even ones with a NULL\noptstring. (Use TOYFLAG_NOHELP to disable.) Produces the same output\nas \"help command\". --version shows toybox version."

#define HELP_toybox_help "Include help text for each command."

#define HELP_toybox_float "Include floating point support infrastructure and commands that\nrequire it."

#define HELP_toybox_libz "Use libz for gz support."

#define HELP_toybox_libcrypto "Use faster hash functions out of external -lcrypto library."

#define HELP_toybox_smack "Include SMACK options in commands like ls for systems like Tizen."

#define HELP_toybox_selinux "Include SELinux options in commands such as ls, and add\nSELinux-specific commands such as chcon to the Android menu."

#define HELP_toybox_lsm_none "Don't try to achieve \"watertight\" by plugging the holes in a\ncollander, instead use conventional unix security (and possibly\nLinux Containers) for a simple straightforward system."

#define HELP_toybox_suid "Support for the Set User ID bit, to install toybox suid root and drop\npermissions for commands which do not require root access. To use\nthis change ownership of the file to the root user and set the suid\nbit in the file permissions:\n\nchown root:root toybox; chmod +s toybox\n\nprompt \"Security Blanket\"\ndefault TOYBOX_LSM_NONE\nhelp\nSelect a Linux Security Module to complicate your system\nuntil you can't find holes in it."

#define HELP_toybox "usage: toybox [--long | --help | --version | [COMMAND] [ARGUMENTS...]]\n\nWith no arguments, \"toybox\" shows available COMMAND names. Add --long\nto include suggested install path for each command, see\nhttps://landley.net/toybox/faq.html#install for details.\n\nFirst argument is name of a COMMAND to run, followed by any ARGUMENTS\nto that command. Most toybox commands also understand:\n\n--help		Show command help (only)\n--version	Show toybox version (only)\n\nThe filename \"-\" means stdin/stdout, and \"--\" stops argument parsing.\n\nNumerical arguments accept a single letter suffix for\nkilo, mega, giga, tera, peta, and exabytes, plus an additional\n\"d\" to indicate decimal 1000's instead of 1024.\n\nDurations can be decimal fractions and accept minute (\"m\"), hour (\"h\"),\nor day (\"d\") suffixes (so 0.1m = 6s)."

#define HELP_setenforce "usage: setenforce [enforcing|permissive|1|0]\n\nSets whether SELinux is enforcing (1) or permissive (0)."

#define HELP_sendevent "usage: sendevent DEVICE TYPE CODE VALUE\n\nSends a Linux input event."

#define HELP_runcon "usage: runcon CONTEXT COMMAND [ARGS...]\n\nRun a command in a specified security context."

#define HELP_restorecon "usage: restorecon [-D] [-F] [-R] [-n] [-v] FILE...\n\nRestores the default security contexts for the given files.\n\n-D	Apply to /data/data too\n-F	Force reset\n-R	Recurse into directories\n-n	Don't make any changes; useful with -v to see what would change\n-v	Verbose"

#define HELP_log "usage: log [-p PRI] [-t TAG] [MESSAGE...]\n\nLogs message (or stdin) to logcat.\n\n-p	Use the given priority instead of INFO:\n	d: DEBUG  e: ERROR  f: FATAL  i: INFO  v: VERBOSE  w: WARN  s: SILENT\n-t	Use the given tag instead of \"log\""

#define HELP_load_policy "usage: load_policy FILE\n\nLoad the specified SELinux policy file."

#define HELP_getenforce "usage: getenforce\n\nShows whether SELinux is disabled, enforcing, or permissive."

#define HELP_skeleton_alias "usage: skeleton_alias [-dq] [-b NUMBER]\n\nExample of a second command with different arguments in the same source\nfile as the first. This allows shared infrastructure outside of lib/."

#define HELP_skeleton "usage: skeleton [-a] [-b STRING] [-c NUMBER] [-d LIST] [-e COUNT] [...]\n\nTemplate for new commands. You don't need this.\n\nWhen creating a new command, copy this file and delete the parts you\ndon't need. Be sure to replace all instances of \"skeleton\" (upper and lower\ncase) with your new command name.\n\nFor simple commands, \"hello.c\" is probably a better starting point."

#define HELP_logpath "usage: logpath ...\n\nAppend command line to $LOGPATH, then call second instance\nof command in $PATH."

#define HELP_hostid "usage: hostid\n\nPrint the numeric identifier for the current host."

#define HELP_hello "usage: hello\n\nA hello world program.\n\nMostly used as a simple template for adding new commands.\nOccasionally nice to smoketest kernel booting via \"init=/usr/bin/hello\"."

#define HELP_demo_utf8towc "usage: demo_utf8towc\n\nPrint differences between toybox's utf8 conversion routines vs libc du jour."

#define HELP_demo_scankey "usage: demo_scankey\n\nMove a letter around the screen. Hit ESC to exit."

#define HELP_demo_number "usage: demo_number [-hsbi] [-D LEN] NUMBER...\n\n-D	output field is LEN chars\n-M	input units (index into bkmgtpe)\n-c	Comma comma down do be do down down\n-b	Use \"B\" for single byte units (HR_B)\n-d	Decimal units\n-h	Human readable\n-s	Space between number and units (HR_SPACE)"

#define HELP_demo_many_options "usage: demo_many_options -[a-zA-Z]\n\nPrint the optflags value of the command arguments, in hex."

#define HELP_umount "usage: umount [-a [-t TYPE[,TYPE...]]] [-vrfD] [DIR...]\n\nUnmount the listed filesystems.\n\n-a	Unmount all mounts in /proc/mounts instead of command line list\n-D	Don't free loopback device(s)\n-f	Force unmount\n-l	Lazy unmount (detach from filesystem now, close when last user does)\n-n	Don't use /proc/mounts\n-r	Remount read only if unmounting fails\n-t	Restrict \"all\" to mounts of TYPE (or use \"noTYPE\" to skip)\n-v	Verbose"

#define HELP_sync "usage: sync\n\nWrite pending cached data to disk (synchronize), blocking until done."

#define HELP_su "usage: su [-lp] [-u UID] [-g GID,...] [-s SHELL] [-c CMD] [USER [COMMAND...]]\n\nSwitch user, prompting for password of new user when not run as root.\n\nWith one argument, switch to USER and run user's shell from /etc/passwd.\nWith no arguments, USER is root. If COMMAND line provided after USER,\nexec() it as new USER (bypassing shell). If -u or -g specified, first\nargument (if any) isn't USER (it's COMMAND).\n\nfirst argument is USER name to switch to (which must exist).\nNon-root users are prompted for new user's password.\n\n-s	Shell to use (default is user's shell from /etc/passwd)\n-c	Command line to pass to -s shell (ala sh -c \"CMD\")\n-l	Reset environment as if new login.\n-u	Switch to UID instead of USER\n-g	Switch to GID (only root allowed, can be comma separated list)\n-p	Preserve environment (except for $PATH and $IFS)"

#define HELP_seq "usage: seq [-w|-f fmt_str] [-s sep_str] [first] [increment] last\n\nCount from first to last, by increment. Omitted arguments default\nto 1. Two arguments are used as first and last. Arguments can be\nnegative or floating point.\n\n-f	Use fmt_str as a printf-style floating point format string\n-s	Use sep_str as separator, default is a newline character\n-w	Pad to equal width with leading zeroes"

#define HELP_pidof "usage: pidof [-s] [-o omitpid[,omitpid...]] [NAME...]\n\nPrint the PIDs of all processes with the given names.\n\n-o	Omit PID(s)\n-s	Single shot, only return one pid\n-x	Match shell scripts too"

#define HELP_passwd_sad "Password changes are checked to make sure they're at least 6 chars long,\ndon't include the entire username (but not a subset of it), or the entire\nprevious password (but changing password1, password2, password3 is fine).\nThis heuristic accepts \"aaaaaa\" and \"123456\"."

#define HELP_passwd "usage: passwd [-a ALGO] [-dlu] [USER]\n\nUpdate user's login password. Defaults to current user.\n\n-a ALGO	Encryption method (des, md5, sha256, sha512) default: md5\n-d		Set password to ''\n-l		Lock (disable) account\n-u		Unlock (enable) account"

#define HELP_mount "usage: mount [-afFrsvw] [-t TYPE] [-o OPTION,] [[DEVICE] DIR]\n\nMount new filesystem(s) on directories. With no arguments, display existing\nmounts.\n\n-a	Mount all entries in /etc/fstab (with -t, only entries of that TYPE)\n-O	Only mount -a entries that have this option\n-f	Fake it (don't actually mount)\n-r	Read only (same as -o ro)\n-w	Read/write (default, same as -o rw)\n-t	Specify filesystem type\n-v	Verbose\n\nOPTIONS is a comma separated list of options, which can also be supplied\nas --longopts.\n\nAutodetects loopback mounts (a file on a directory) and bind mounts (file\non file, directory on directory), so you don't need to say --bind or --loop.\nYou can also \"mount -a /path\" to mount everything in /etc/fstab under /path,\neven if it's noauto. DEVICE starting with UUID= is identified by blkid -U,\nand DEVICE starting with LABEL= is identified by blkid -L."

#define HELP_mktemp "usage: mktemp [-dqtu] [-p DIR] [TEMPLATE]\n\nSafely create a new file \"DIR/TEMPLATE\" and print its name.\n\n-d	Create directory instead of file (--directory)\n-p	Put new file in DIR (--tmpdir)\n-q	Quiet, no error messages\n-t	Prefer $TMPDIR > DIR > /tmp (default DIR > $TMPDIR > /tmp)\n-u	Don't create anything, just print what would be created\n\nEach X in TEMPLATE is replaced with a random printable character. The\ndefault TEMPLATE is tmp.XXXXXXXXXX."

#define HELP_mknod_z "usage: mknod [-Z CONTEXT] ...\n\n-Z	Set security context to created file"

#define HELP_mknod "usage: mknod [-m MODE] NAME TYPE [MAJOR MINOR]\n\nCreate a special file NAME with a given type. TYPE is b for block device,\nc or u for character device, p for named pipe (which ignores MAJOR/MINOR).\n\n-m	Mode (file permissions) of new device, in octal or u+x format"

#define HELP_sha512sum "See md5sum"

#define HELP_sha384sum "See md5sum"

#define HELP_sha256sum "See md5sum"

#define HELP_sha224sum "See md5sum"

#define HELP_sha1sum "See md5sum"

#define HELP_md5sum "usage: ???sum [-bcs] [FILE]...\n\nCalculate hash for each input file, reading from stdin if none, writing\nhexadecimal digits to stdout for each input file (md5=32 hex digits,\nsha1=40, sha224=56, sha256=64, sha384=96, sha512=128) followed by filename.\n\n-b	Brief (hash only, no filename)\n-c	Check each line of each FILE is the same hash+filename we'd output\n-s	No output, exit status 0 if all hashes match, 1 otherwise"

#define HELP_killall "usage: killall [-l] [-iqv] [-SIGNAL|-s SIGNAL] PROCESS_NAME...\n\nSend a signal (default: TERM) to all processes with the given names.\n\n-i	Ask for confirmation before killing\n-l	Print list of all available signals\n-q	Don't print any warnings or error messages\n-s	Send SIGNAL instead of SIGTERM\n-v	Report if the signal was successfully sent\n-w	Wait until all signaled processes are dead"

#define HELP_dnsdomainname "usage: dnsdomainname\n\nShow domain this system belongs to (same as hostname -d)."

#define HELP_hostname "usage: hostname [-bdsf] [-F FILENAME] [newname]\n\nGet/set the current hostname.\n\n-b	Set hostname to 'localhost' if otherwise unset\n-d	Show DNS domain name (no host)\n-f	Show fully-qualified name (host+domain, FQDN)\n-F	Set hostname to contents of FILENAME\n-s	Show short host name (no domain)"

#define HELP_zcat "usage: zcat [-f] [FILE...]\n\nDecompress files to stdout. Like `gzip -dc`.\n\n-f	Force: allow read from tty"

#define HELP_gunzip "usage: gunzip [-cfkt] [FILE...]\n\nDecompress files. With no files, decompresses stdin to stdout.\nOn success, the input files are removed and replaced by new\nfiles without the .gz suffix.\n\n-c	Output to stdout (act as zcat)\n-f	Force: allow read from tty\n-k	Keep input files (default is to remove)\n-t	Test integrity"

#define HELP_gzip "usage: gzip [-19cdfkt] [FILE...]\n\nCompress files. With no files, compresses stdin to stdout.\nOn success, the input files are removed and replaced by new\nfiles with the .gz suffix.\n\n-c	Output to stdout\n-d	Decompress (act as gunzip)\n-f	Force: allow overwrite of output file\n-k	Keep input files (default is to remove)\n-t	Test integrity\n-#	Compression level 1-9 (1:fastest, 6:default, 9:best)"

#define HELP_dmesg "usage: dmesg [-Cc] [-r|-t|-T] [-n LEVEL] [-s SIZE] [-w|-W]\n\nPrint or control the kernel ring buffer.\n\n-C	Clear ring buffer without printing\n-c	Clear ring buffer after printing\n-n	Set kernel logging LEVEL (1-8)\n-r	Raw output (with <level markers>)\n-S	Use syslog(2) rather than /dev/kmsg\n-s	Show the last SIZE many bytes\n-T	Human readable timestamps\n-t	Don't print timestamps\n-w	Keep waiting for more output (aka --follow)\n-W	Wait for output, only printing new messages"

#define HELP_wget_libtls "Enable HTTPS support for wget by linking to LibTLS.\nSupports using libtls, libretls or libtls-bearssl.\n\nUse TOYBOX_LIBCRYPTO to enable HTTPS support via OpenSSL."

#define HELP_wget "usage: wget [OPTIONS]... [URL]\n    --max-redirect          maximum redirections allowed\n-d, --debug                 print lots of debugging information\n-O, --output-document=FILE  specify output filename\n-p, --post-data=DATA        send data in body of POST request\n\nexamples:\n  wget http://www.example.com"

#define HELP_tunctl "usage: tunctl [-dtT] [-u USER] NAME\n\nCreate and delete tun/tap virtual ethernet devices.\n\n-T	Use tap (ethernet frames) instead of tun (ip packets)\n-d	Delete tun/tap device\n-t	Create tun/tap device\n-u	Set owner (user who can read/write device without root access)"

#define HELP_sntp "usage: sntp [-saSdDq] [-r SHIFT] [-mM[ADDRESS]] [-p PORT] [SERVER]\n\nSimple Network Time Protocol client. Query SERVER and display time.\n\n-p	Use PORT (default 123)\n-s	Set system clock suddenly\n-a	Adjust system clock gradually\n-S	Serve time instead of querying (bind to SERVER address if specified)\n-m	Wait for updates from multicast ADDRESS (RFC 4330 suggests 224.0.1.1)\n-M	Multicast server on ADDRESS (RFC 4330 suggests 224.0.1.1)\n-t	TTL (multicast only, default 1)\n-d	Daemonize (run in background re-querying)\n-D	Daemonize but stay in foreground: re-query time every 1000 seconds\n-r	Retry shift (every 1<<SHIFT seconds)\n-q	Quiet (don't display time)"

#define HELP_rfkill "usage: rfkill COMMAND [DEVICE]\n\nEnable/disable wireless devices.\n\nCommands:\nlist [DEVICE]   List current state\nblock DEVICE    Disable device\nunblock DEVICE  Enable device\n\nDEVICE is an index number, or one of:\nall, wlan(wifi), bluetooth, uwb(ultrawideband), wimax, wwan, gps, fm."

#define HELP_ping "usage: ping [OPTIONS] HOST\n\nCheck network connectivity by sending packets to a host and reporting\nits response.\n\nSend ICMP ECHO_REQUEST packets to ipv4 or ipv6 addresses and prints each\necho it receives back, with round trip time. Returns true if host alive.\n\nOptions:\n-4, -6		Force IPv4 or IPv6\n-c CNT		Send CNT many packets (default 3, 0 = infinite)\n-f		Flood (print . and \\b to show drops, default -c 15 -i 0.2)\n-i TIME		Interval between packets (default 1, need root for < .2)\n-I IFACE/IP	Source interface or address\n-m MARK		Tag outgoing packets using SO_MARK\n-q		Quiet (stops after one returns true if host is alive)\n-s SIZE		Data SIZE in bytes (default 56)\n-t TTL		Set Time To Live (number of hops)\n-W SEC		Seconds to wait for response after last -c packet (default 3)\n-w SEC		Exit after this many seconds"

#define HELP_netstat "usage: netstat [-pWrxwutneal]\n\nDisplay networking information. Default is netstat -tuwx\n\n-r	Routing table\n-a	All sockets (not just connected)\n-l	Listening server sockets\n-t	TCP sockets\n-u	UDP sockets\n-w	Raw sockets\n-x	Unix sockets\n-e	Extended info\n-n	Don't resolve names\n-W	Wide display\n-p	Show PID/program name of sockets"

#define HELP_netcat "usage: netcat [-46ELlntUu] [-pqWw #] [-s addr] [-o FILE] {IPADDR PORTNUM|-f FILENAME|COMMAND...}\n\nForward stdin/stdout to a file or network connection.\n\n-4	Force IPv4\n-6	Force IPv6\n-E	Forward stderr\n-f	Use FILENAME (ala /dev/ttyS0) instead of network\n-L	Listen and background each incoming connection (server mode)\n-l	Listen for one incoming connection, then exit\n-n	No DNS lookup\n-o	Hex dump to FILE (show packets, -o- writes hex only to stdout)\n-O	Hex dump to FILE (streaming mode)\n-p	Local port number\n-q	Quit SECONDS after EOF on stdin, even if stdout hasn't closed yet\n-s	Local source address\n-t	Allocate tty\n-u	Use UDP\n-U	Use a UNIX domain socket\n-W	SECONDS timeout for more data on an idle connection\n-w	SECONDS timeout to establish connection\n-z	zero-I/O mode [used for scanning]\n\nWhen listening the COMMAND line is executed as a child process to handle\nan incoming connection. With no COMMAND -l forwards the connection\nto stdin/stdout. If no -p specified, -l prints the port it bound to and\nbackgrounds itself (returning immediately).\n\nFor a quick-and-dirty server, try something like:\nnetcat -s 127.0.0.1 -p 1234 -tL sh -l\n\nOr use \"stty 115200 -F /dev/ttyS0 && stty raw -echo -ctlecho\" with\nnetcat -f to connect to a serial port."

#define HELP_microcom "usage: microcom [-s SPEED] [-X] DEVICE\n\nSimple serial console. Hit CTRL-] for menu.\n\n-s	Set baud rate to SPEED\n-X	Ignore ^] menu escape"

#define HELP_ifconfig "usage: ifconfig [-aS] [INTERFACE [ACTION...]]\n\nDisplay or configure network interface.\n\nWith no arguments, display active interfaces. First argument is interface\nto operate on, one argument by itself displays that interface.\n\n-a	All interfaces displayed, not just active ones\n-S	Short view, one line per interface\n\nStandard ACTIONs to perform on an INTERFACE:\n\nADDR[/MASK]        - set IPv4 address (1.2.3.4/5) and activate interface\nadd|del ADDR[/LEN] - add/remove IPv6 address (1111::8888/128)\nup|down            - activate or deactivate interface\n\nAdvanced ACTIONs (default values usually suffice):\n\ndefault          - remove IPv4 address\nnetmask ADDR     - set IPv4 netmask via 255.255.255.0 instead of /24\ntxqueuelen LEN   - number of buffered packets before output blocks\nmtu LEN          - size of outgoing packets (Maximum Transmission Unit)\nbroadcast ADDR   - Set broadcast address\npointopoint ADDR - PPP and PPPOE use this instead of \"route add default gw\"\nhw TYPE ADDR     - set hardware (mac) address (type = ether|infiniband)\nrename NEWNAME   - rename interface\n\nFlags you can set on an interface (or -remove by prefixing with -):\n\narp       - don't use Address Resolution Protocol to map LAN routes\npromisc   - don't discard packets that aren't to this LAN hardware address\nmulticast - force interface into multicast mode if the driver doesn't\nallmulti  - promisc for multicast packets"

#define HELP_httpd "usage: httpd [-de STR] [-v] [DIR]\n\nServe contents of directory as static web pages.\n\n-e	Escape STR as URL, printing result and exiting.\n-d	Decode escaped STR, printing result and exiting.\n-v	Verbose"

#define HELP_host "usage: host [-v] [-t TYPE] NAME [SERVER]\n\nLook up DNS records for NAME, either domain name or IPv4/IPv6 address to\nreverse lookup, from SERVER or default DNS server(s).\n\n-a	All records\n-t TYPE	Record TYPE (number or ANY A AAAA CNAME MX NS PTR SOA SRV TXT)\n-v	Verbose"

#define HELP_ftpput "An ftpget that defaults to -s instead of -g"

#define HELP_ftpget "usage: ftpget [-cvgslLmMdD] [-P PORT] [-p PASSWORD] [-u USER] HOST [LOCAL] REMOTE\n\nTalk to ftp server. By default get REMOTE file via passive anonymous\ntransfer, optionally saving under a LOCAL name. Can also send, list, etc.\n\n-c	Continue partial transfer\n-p	Use PORT instead of \"21\"\n-P	Use PASSWORD instead of \"ftpget@\"\n-u	Use USER instead of \"anonymous\"\n-v	Verbose\n\nWays to interact with FTP server:\n-d	Delete file\n-D	Remove directory\n-g	Get file (default)\n-l	List directory\n-L	List (filenames only)\n-m	Move file on server from LOCAL to REMOTE\n-M	mkdir\n-s	Send file"

#define HELP_yes "usage: yes [args...]\n\nRepeatedly output line until killed. If no args, output 'y'."

#define HELP_xxd "usage: xxd [-eipr] [-cglos N] [file]\n\nHexdump a file to stdout. If no file is listed, copy from stdin.\nFilename \"-\" is a synonym for stdin.\n\n-c N	Show N bytes per line (default 16)\n-e	Little-endian\n-g N	Group bytes by adding a ' ' every N bytes (default 2)\n-i	Output include file (CSV hex bytes, plus C header/footer if not stdin)\n-l N	Limit of N bytes before stopping (default is no limit)\n-o N	Add N to display offset\n-p	Plain hexdump (30 bytes/line, no grouping. With -c 0 no wrap/group)\n-r	Reverse operation: turn a hexdump into a binary file\n-s N	Skip to offset N"

#define HELP_which "usage: which [-a] filename ...\n\nSearch $PATH for executable files matching filename(s).\n\n-a	Show all matches"

#define HELP_watchdog "usage: watchdog [-F] [-t UPDATE] [-T DEADLINE] DEV\n\nStart the watchdog timer at DEV with optional timeout parameters.\n\n-F	run in the foreground (do not daemonize)\n-t	poke watchdog every UPDATE seconds (default 4)\n-T	reboot if not poked for DEADLINE seconds (default 60)"

#define HELP_watch "usage: watch [-tebx] [-n SEC] COMMAND...\n\nRun COMMAND every -n seconds, showing output that fits terminal, q to quit.\n\n-n	Number of seconds between repeats (default 2.0)\n-t	Don't print header\n-e	Exit on error\n-b	Beep on command error\n-x	Exec command directly (without \"sh -c\")"

#define HELP_w "usage: w\n\nShow who is logged on and since how long they logged in."

#define HELP_vmstat "usage: vmstat [-n] [DELAY [COUNT]]\n\nPrint virtual memory statistics, repeating each DELAY seconds, COUNT times.\n(With no DELAY, prints one line. With no COUNT, repeats until killed.)\n\nShow processes running and blocked, kilobytes swapped, free, buffered, and\ncached, kilobytes swapped in and out per second, file disk blocks input and\noutput per second, interrupts and context switches per second, percent\nof CPU time spent running user code, system code, idle, and awaiting I/O.\nFirst line is since system started, later lines are since last line.\n\n-n	Display the header only once"

#define HELP_vconfig "usage: vconfig COMMAND [OPTIONS]\n\nCreate and remove virtual ethernet devices\n\nadd             [interface-name] [vlan_id]\nrem             [vlan-name]\nset_flag        [interface-name] [flag-num]       [0 | 1]\nset_egress_map  [vlan-name]      [skb_priority]   [vlan_qos]\nset_ingress_map [vlan-name]      [skb_priority]   [vlan_qos]\nset_name_type   [name-type]"

#define HELP_uuidgen "usage: uuidgen\n\nCreate and print a new RFC4122 random UUID."

#define HELP_usleep "usage: usleep MICROSECONDS\n\nPause for MICROSECONDS microseconds."

#define HELP_uptime "usage: uptime [-ps]\n\nTell the current time, how long the system has been running, the number\nof users, and the system load averages for the past 1, 5 and 15 minutes.\n\n-p	Pretty (human readable) uptime\n-s	Since when has the system been up?"

#define HELP_uclampset "usage: uclampset [-m MIN] [-M MAX] {-p PID | COMMAND...}\n\nSet or query process utilization limits ranging from 0 to 1024, or -1 to\nreset to system default. With no arguments, prints current values.\n\n-m MIN      Reserve at least this much CPU utilization for task\n-M MAX      Limit task to at most this much CPU utilization\n-p PID	Apply to PID rather than new COMMAND\n-R	Reset child processes to default values on fork\n-a	Apply to all threads for the given PID"

#define HELP_ts "usage: ts [-is] [FORMAT]\n\nAdd timestamps to each line in pipeline. Default format without options\n\"%b %d %H:%M:%S\", with -i or -s \"%H:%M:%S\".\n\n-i	Incremental (since previous line)\n-m	Add milliseconds\n-s	Since start"

#define HELP_truncate "usage: truncate [-c] -s SIZE file...\n\nSet length of file(s), extending sparsely if necessary.\n\n-c	Don't create file if it doesn't exist\n-s	New size (with optional prefix and suffix)\n\nSIZE prefix: + add, - subtract, < shrink to, > expand to,\n             / multiple rounding down, % multiple rounding up\nSIZE suffix: k=1024, m=1024^2, g=1024^3, t=1024^4, p=1024^5, e=1024^6"

#define HELP_timeout "usage: timeout [-iv] [-k DURATION] [-s SIGNAL] DURATION COMMAND...\n\nRun command line as a child process, sending child a signal if the\ncommand doesn't exit soon enough.\n\nDURATION can be a decimal fraction. An optional suffix can be \"m\"\n(minutes), \"h\" (hours), \"d\" (days), or \"s\" (seconds, the default).\n\n-i	Only kill for inactivity (restart timeout when command produces output)\n-k	Send KILL signal if child still running this long after first signal\n-s	Send specified signal (default TERM)\n-v	Verbose\n--foreground       Don't create new process group\n--preserve-status  Exit with the child's exit status"

#define HELP_taskset "usage: taskset [-ap] [mask] [PID | cmd [args...]]\n\nLaunch a new task which may only run on certain processors, or change\nthe processor affinity of an existing PID.\n\nMask is a hex string where each bit represents a processor the process\nis allowed to run on. PID without a mask displays existing affinity.\n\n-p	Set/get the affinity of given PID instead of a new command\n-a	Set/get the affinity of all threads of the PID"

#define HELP_nproc "usage: nproc [--all]\n\nPrint number of processors.\n\n--all	Show all processors, not just ones this task can run on"

#define HELP_tac "usage: tac [FILE...]\n\nOutput lines in reverse order."

#define HELP_sysctl "usage: sysctl [-aeNnqw] [-p [FILE] | KEY[=VALUE]...]\n\nRead/write system control data (under /proc/sys).\n\n-a	Show all values\n-e	Don't warn about unknown keys\n-N	Don't print key values\n-n	Don't print key names\n-p	Read values from FILE (default /etc/sysctl.conf)\n-q	Don't show value after write\n-w	Only write values (object to reading)"

#define HELP_switch_root "usage: switch_root [-c /dev/console] NEW_ROOT NEW_INIT...\n\nUse from PID 1 under initramfs to free initramfs, chroot to NEW_ROOT,\nand exec NEW_INIT.\n\n-c	Redirect console to device in NEW_ROOT\n-h	Hang instead of exiting on failure (avoids kernel panic)"

#define HELP_swapon "usage: swapon [-d] [-p priority] filename\n\nEnable swapping on a given device/file.\n\n-d	Discard freed SSD pages\n-p	Priority (highest priority areas allocated first)"

#define HELP_swapoff "usage: swapoff FILE\n\nDisable swapping on a device or file."

#define HELP_stat "usage: stat [-tfL] [-c FORMAT] FILE...\n\nDisplay status of files or filesystems.\n\n-c	Output specified FORMAT string instead of default\n-f	Display filesystem status instead of file status\n-L	Follow symlinks\n-t	terse (-c \"%n %s %b %f %u %g %D %i %h %t %T %X %Y %Z %o\")\n	      (with -f = -c \"%n %i %l %t %s %S %b %f %a %c %d\")\n\nThe valid format escape sequences for files:\n%a  Access bits (octal) |%A  Access bits (flags)|%b  Size/512\n%B  Bytes per %b (512)  |%C  Security context   |%d  Device ID (dec)\n%D  Device ID (hex)     |%f  All mode bits (hex)|%F  File type\n%g  Group ID            |%G  Group name         |%h  Hard links\n%i  Inode               |%m  Mount point        |%n  Filename\n%N  Long filename       |%o  I/O block size     |%s  Size (bytes)\n%t  Devtype major (hex) |%T  Devtype minor (hex)|%u  User ID\n%U  User name           |%x  Access time        |%X  Access unix time\n%y  Modification time   |%Y  Mod unix time      |%z  Creation time\n%Z  Creation unix time\n\nThe valid format escape sequences for filesystems:\n%a  Available blocks    |%b  Total blocks       |%c  Total inodes\n%d  Free inodes         |%f  Free blocks        |%i  File system ID\n%l  Max filename length |%n  File name          |%s  Best transfer size\n%S  Actual block size   |%t  FS type (hex)      |%T  FS type (driver name)"

#define HELP_shuf "usage: shuf [-ze] [-n COUNT] [FILE...]\n\nWrite lines of input to output in random order.\n\n-z	Input/output lines are NUL terminated.\n-n	Stop after COUNT many output lines.\n-e	Echo mode: arguments are inputs to shuffle, not files to read."

#define HELP_shred "usage: shred [-fuxz] [-n COUNT] [-o OFFSET] [-s SIZE] FILE...\n\nSecurely delete a file by overwriting its contents with random data.\n\n-f		Force (chmod if necessary)\n-n COUNT	Random overwrite iterations (default 1)\n-o OFFSET	Start at OFFSET\n-s SIZE		Use SIZE instead of detecting file size\n-u		Unlink (actually delete file when done)\n-x		Use exact size (default without -s rounds up to next 4k)\n-z		Zero at end\n\nNote: data journaling filesystems render this command useless, you must\noverwrite all free space (fill up disk) to erase old data on those."

#define HELP_sha3sum "usage: sha3sum [-bS] [-a BITS] [FILE...]\n\nHash function du jour.\n\n-a	Produce a hash BITS long (default 224)\n-b	Brief (hash only, no filename)\n-S	Use SHAKE termination byte instead of SHA3 (ask FIPS why)"

#define HELP_setsid "usage: setsid [-cdw] command [args...]\n\nRun process in a new session.\n\n-d	Detach from tty\n-c	Control tty (repeat to steal)\n-w	Wait for child (and exit with its status)"

#define HELP_setfattr "usage: setfattr [-h] [-x|-n NAME] [-v VALUE] FILE...\n\nWrite POSIX extended attributes.\n\n-h	Do not dereference symlink\n-n	Set given attribute\n-x	Remove given attribute\n-v	Set value for attribute -n (default is empty)"

#define HELP_rtcwake "usage: rtcwake [-aluv] [-d FILE] [-m MODE] [-s SECS] [-t UNIX]\n\nEnter the given sleep state until the given time.\n\n-a	RTC uses time specified in /etc/adjtime\n-d FILE	Device to use (default /dev/rtc)\n-l	RTC uses local time\n-m	Mode (--list-modes to see those supported by your kernel):\n	  standby  S1: default              mem     S3: suspend to RAM\n	  disk     S4: suspend to disk      off     S5: power off\n	  disable  Cancel current alarm     freeze  stop processes/processors\n	  no       just set wakeup time     on      just poll RTC for alarm\n	  show     just show current alarm\n-s SECS	Wake SECS seconds from now\n-t UNIX	Wake UNIX seconds from epoch\n-u	RTC uses UTC\n-v	Verbose"

#define HELP_rmmod "usage: rmmod [-wf] MODULE...\n\nUnload the given kernel modules.\n\n-f	Force unload of a module\n-w	Wait until the module is no longer used"

#define HELP_rev "usage: rev [FILE...]\n\nOutput each line reversed, when no files are given stdin is used."

#define HELP_reset "usage: reset\n\nReset the terminal."

#define HELP_reboot "usage: reboot/halt/poweroff [-fn] [-d DELAY]\n\nRestart, halt, or power off the system.\n\n-d	Wait DELAY before proceeding (in seconds or m/h/d suffix: -d 1.5m = 90s)\n-f	Force reboot (don't signal init, reboot directly)\n-n	Don't sync filesystems before reboot"

#define HELP_realpath "usage: realpath [-LPemqsz] [--relative-base DIR] [-R DIR] FILE...\n\nDisplay the canonical absolute pathname\n\n-R Show ../path relative to DIR (--relative-to)\n-L Logical path (resolve .. before symlinks)\n-P Physical path (default)\n-e Canonical path to existing entry (fail if missing)\n-m Ignore missing entries, show where it would be\n-q Quiet (no error messages)\n-s Don't expand symlinks\n-z NUL instead of newline\n--relative-base  If path under DIR trim off prefix"

#define HELP_readlink "usage: readlink [-efmnqz] FILE...\n\nWith no options, show what symlink points to, return error if not symlink.\n\nOptions for producing canonical paths (all symlinks/./.. resolved):\n\n-e	Canonical path to existing entry (fail if missing)\n-f	Full path (fail if directory missing)\n-m	Ignore missing entries, show where it would be\n-n	No trailing newline\n-q	Quiet (no error messages)\n-z	NUL instead of newline"

#define HELP_readelf "usage: readelf [-AadehlnSs] [-p SECTION] [-x SECTION] [file...]\n\nDisplays information about ELF files.\n\n-A	Show architecture-specific info\n-a	Equivalent to -AdhlnSs\n-d	Show dynamic section\n-e	Headers (equivalent to -hlS)\n-h	Show ELF header\n-l	Show program headers\n-n	Show notes\n-p S	Dump strings found in named/numbered section\n-S	Show section headers\n-s	Show symbol tables (.dynsym and .symtab)\n-x S	Hex dump of named/numbered section\n\n--dyn-syms	Show just .dynsym symbol table"

#define HELP_readahead "usage: readahead FILE...\n\nPreload files into disk cache."

#define HELP_pwgen "usage: pwgen [-cAn0yrsBC1v] [-r CHARS] [LENGTH] [COUNT]\n\nGenerate human-readable random passwords. Default output to tty fills screen\nwith passwords to defeat shoulder surfing (pick one and clear the screen).\n\n-0	No numbers (--no-numerals)\n-1	Output one per line\n-A	No capital letters (--no-capitalize)\n-B	Avoid ambiguous characters like 0O and 1lI (--ambiguous)\n-C	Output in columns\n-c	Add capital letters (--capitalize)\n-n	Add numbers (--numerals)\n-r	Don't include the given CHARS (--remove)\n-v	No vowels.\n-y	Add punctuation (--symbols)"

#define HELP_pwdx "usage: pwdx PID...\n\nPrint working directory of processes listed on command line."

#define HELP_printenv "usage: printenv [-0] [env_var...]\n\nPrint environment variables.\n\n-0	Use \\0 as delimiter instead of \\n"

#define HELP_pmap "usage: pmap [-pqx] PID...\n\nReport the memory map of a process or processes.\n\n-p	Show full paths\n-q	Do not show header or footer\n-x	Show the extended format"

#define HELP_pivot_root "usage: pivot_root OLD NEW\n\nSwap OLD and NEW filesystems (as if by simultaneous mount --move), and\nmove all processes with chdir or chroot under OLD into NEW (including\nkernel threads) so OLD may be unmounted.\n\nThe directory NEW must exist under OLD. This doesn't work on initramfs,\nwhich can't be moved (about the same way PID 1 can't be killed; see\nswitch_root instead)."

#define HELP_partprobe "usage: partprobe DEVICE...\n\nTell the kernel about partition table changes\n\nAsk the kernel to re-read the partition table on the specified devices."

#define HELP_deallocvt "usage: deallocvt [NUM]\n\nDeallocate unused virtual terminals, either a specific /dev/ttyNUM, or all."

#define HELP_chvt "usage: chvt NUM\n\nChange to virtual terminal number NUM. (This only works in text mode.)\n\nVirtual terminals are the Linux VGA text mode (or framebuffer) displays,\nswitched between via alt-F1, alt-F2, etc. Use ctrl-alt-F1 to switch\nfrom X11 to a virtual terminal, and alt-F6 (or F7, or F8) to get back."

#define HELP_openvt "usage: openvt [-c NUM] [-sw] COMMAND...\n\nRun COMMAND on a new virtual terminal.\n\n-c NUM  Use VT NUM\n-s    Switch to the new VT\n-w    Wait for command to exit (with -s, deallocates VT on exit)"

#define HELP_oneit "usage: oneit [-prn3] [-c CONSOLE] [COMMAND...]\n\nSimple init program that runs a single supplied command line with a\ncontrolling tty (so CTRL-C can kill it).\n\n-c	Which console device to use (/dev/console doesn't do CTRL-C, etc)\n-p	Power off instead of rebooting when command exits\n-r	Restart child when it exits\n-n	No reboot, just relaunch command line\n-3	Write 32 bit PID of each exiting reparented process to fd 3 of child\n	(Blocking writes, child must read to avoid eventual deadlock.)\n\nSpawns a single child process (because PID 1 has signals blocked)\nin its own session, reaps zombies until the child exits, then\nreboots the system (or powers off with -p, or restarts the child with -r).\n\nResponds to SIGUSR1 by halting the system, SIGUSR2 by powering off,\nand SIGTERM or SIGINT reboot."

#define HELP_nsenter "usage: nsenter [-t pid] [-F] [-i] [-m] [-n] [-p] [-u] [-U] COMMAND...\n\nRun COMMAND in an existing (set of) namespace(s).\n\n-a	Enter all supported namespaces (--all)\n-F	don't fork, even if -p is used (--no-fork)\n-t	PID to take namespaces from    (--target)\n\nThe namespaces to switch are:\n\n-C	Control groups (--cgroup)\n-i	SysV IPC: message queues, semaphores, shared memory (--ipc)\n-m	Mount/unmount tree (--mount)\n-n	Network address, sockets, routing, iptables (--net)\n-p	Process IDs and init, will fork unless -F is used (--pid)\n-u	Host and domain names (--uts)\n-U	UIDs, GIDs, capabilities (--user)\n\nIf -t isn't specified, each namespace argument must provide a path\nto a namespace file, ala \"-i=/proc/$PID/ns/ipc\""

#define HELP_unshare "usage: unshare [-imnpuUr] COMMAND...\n\nCreate new container namespace(s) for this process and its children, allowing\nthe new set of processes to have a different view of the system than the\nparent process.\n\n-a	Unshare all supported namespaces\n-f	Fork command in the background (--fork)\n-r	Become root (map current euid/egid to 0/0, implies -U) (--map-root-user)\n\nAvailable namespaces:\n-C	Control groups (--cgroup)\n-i	SysV IPC (message queues, semaphores, shared memory) (--ipc)\n-m	Mount/unmount tree (--mount)\n-n	Network address, sockets, routing, iptables (--net)\n-p	Process IDs and init (--pid)\n-u	Host and domain names (--uts)\n-U	UIDs, GIDs, capabilities (--user)\n\nEach namespace can take an optional argument, a persistent mountpoint usable\nby the nsenter command to add new processes to that the namespace. (Specify\nmultiple namespaces to unshare separately, ala -c -i -m because -cim is -c\nwith persistent mount \"im\".)"

#define HELP_nbd_server "usage: nbd-server [-r] FILE\n\nServe a Network Block Device from FILE on stdin/out (ala inetd).\n\n-r	Read only export"

#define HELP_nbd_client "usage: nbd-client [-ns] [-b BLKSZ] HOST PORT DEVICE\n\n-b	Block size (default 4096)\n-n	Do not daemonize\n-s	nbd swap support (lock server into memory)"

#define HELP_mountpoint "usage: mountpoint [-qd] DIR\n       mountpoint [-qx] DEVICE\n\nCheck whether the directory or device is a mountpoint.\n\n-q	Be quiet, return zero if directory is a mountpoint\n-d	Print major/minor device number of the directory\n-x	Print major/minor device number of the block device"

#define HELP_modinfo "usage: modinfo [-0] [-b basedir] [-k kernel] [-F field] [module|file...]\n\nDisplay module fields for modules specified by name or .ko path.\n\n-F  Only show the given field\n-0  Separate fields with NUL rather than newline\n-b  Use <basedir> as root for /lib/modules/\n-k  Look in given directory under /lib/modules/"

#define HELP_mkswap "usage: mkswap [-L LABEL] DEVICE\n\nSet up a Linux swap area on a device or file."

#define HELP_mkpasswd "usage: mkpasswd [-P FD] [-m TYPE] [-S SALT] [PASSWORD] [SALT]\n\nEncrypt PASSWORD using crypt(3), with either random or provided SALT.\n\n-P FD	Read password from file descriptor FD\n-m TYPE	Encryption method (des, md5, sha256, or sha512; default is des)"

#define HELP_mix "usage: mix [-d DEV] [-c CHANNEL] [-l VOL] [-r RIGHT]\n\nList OSS sound channels (module snd-mixer-oss), or set volume(s).\n\n-c CHANNEL	Set/show volume of CHANNEL (default first channel found)\n-d DEV		Device node (default /dev/mixer)\n-l VOL		Volume level\n-r RIGHT	Volume of right stereo channel (with -r, -l sets left volume)"

#define HELP_memeater "usage: memeater [-M] BYTES\n\nConsume the specified amount of memory and wait to be killed.\n\n-M	Don't mlock() the memory (let it swap out)."

#define HELP_mcookie "usage: mcookie [-vV]\n\nGenerate a 128-bit strong random number.\n\n-v  show entropy source (verbose)\n-V  show version"

#define HELP_makedevs "usage: makedevs [-d device_table] rootdir\n\nCreate a range of special files as specified in a device table.\n\n-d	File containing device table (default reads from stdin)\n\nEach line of the device table has the fields:\n<name> <type> <mode> <uid> <gid> <major> <minor> <start> <increment> <count>\nWhere name is the file name, and type is one of the following:\n\nb	Block device\nc	Character device\nd	Directory\nf	Regular file\np	Named pipe (fifo)\n\nOther fields specify permissions, user and group id owning the file,\nand additional fields for device special files. Use '-' for blank entries,\nunspecified fields are treated as '-'."

#define HELP_lsusb "usage: lsusb [-i]\n\nList USB hosts/devices.\n\n-i	ID database (default /etc/usb.ids[.gz])"

#define HELP_lspci "usage: lspci [-ekmn] [-i FILE]\n\nList PCI devices.\n\n-e	Extended (6 digit) class\n-i	ID database (default /etc/pci.ids[.gz])\n-k	Show kernel driver\n-m	Machine readable\n-n	Numeric output (-nn for both)\n-D	Print domain numbers\n-x	Hex dump of config space (64 bytes; -xxx for 256, -xxxx for 4096)"

#define HELP_lsmod "usage: lsmod\n\nDisplay the currently loaded modules, their sizes and their dependencies."

#define HELP_chattr "usage: chattr [-R] [-+=AacDdijsStTu] [-p PROJID] [-v VERSION] [FILE...]\n\nChange file attributes on a Linux file system.\n\n-R	Recurse\n-p	Set the file's project number\n-v	Set the file's version/generation number\n\nOperators:\n  '-' Remove attributes\n  '+' Add attributes\n  '=' Set attributes\n\nAttributes:\n  A  No atime                     a  Append only\n  C  No COW                       c  Compression\n  D  Synchronous dir updates      d  No dump\n  E  Encrypted                    e  Extents\n  F  Case-insensitive (casefold)\n  I  Indexed directory            i  Immutable\n  j  Journal data\n  N  Inline data in inode\n  P  Project hierarchy\n  S  Synchronous file updates     s  Secure delete\n  T  Top of dir hierarchy         t  No tail-merging\n  u  Allow undelete\n  V  Verity"

#define HELP_lsattr "usage: lsattr [-Radlpv] [FILE...]\n\nList file attributes on a Linux file system.\nFlag letters are defined in chattr help.\n\n-R	Recursively list attributes of directories and their contents\n-a	List all files in directories, including files that start with '.'\n-d	List directories like other files, rather than listing their contents\n-l	List long flag names\n-p	List the file's project number\n-v	List the file's version/generation number"

#define HELP_losetup "usage: losetup [-cdrs] [-o OFFSET] [-S SIZE] {-d DEVICE...|-j FILE|-af|{DEVICE FILE}}\n\nAssociate a loopback device with a file, or show current file (if any)\nassociated with a loop device.\n\nInstead of a device:\n-a	Iterate through all loopback devices\n-f	Find first unused loop device (may create one)\n-j FILE	Iterate through all loopback devices associated with FILE\n\nexisting:\n-c	Check capacity (file size changed)\n-d DEV	Detach loopback device\n-D	Detach all loopback devices\n\nnew:\n-s	Show device name (alias --show)\n-o OFF	Start association at offset OFF into FILE\n-r	Read only\n-S SIZE	Limit SIZE of loopback association (alias --sizelimit)"

#define HELP_login "usage: login [-p] [-h host] [-f USERNAME] [USERNAME]\n\nLog in as a user, prompting for username and password if necessary.\n\n-p	Preserve environment\n-h	The name of the remote host for this login\n-f	login as USERNAME without authentication"

#define HELP_linux32 "usage: linux32 [COMMAND...]\n\nTell uname -m to lie to autoconf (to build 32 bit binaries on 64 bit kernel)."

#define HELP_iorenice "usage: iorenice PID [CLASS] [PRIORITY]\n\nDisplay or change I/O priority of existing process. CLASS can be\n\"rt\" for realtime, \"be\" for best effort, \"idle\" for only when idle, or\n\"none\" to leave it alone. PRIORITY can be 0-7 (0 is highest, default 4)."

#define HELP_ionice "usage: ionice [-t] [-c CLASS] [-n LEVEL] [COMMAND...|-p PID]\n\nChange the I/O scheduling priority of a process. With no arguments\n(or just -p), display process' existing I/O class/priority.\n\n-c	CLASS = 1-3: 1(realtime), 2(best-effort, default), 3(when-idle)\n-n	LEVEL = 0-7: (0 is highest priority, default = 5)\n-p	Affect existing PID instead of spawning new child\n-t	Ignore failure to set I/O priority\n\nSystem default iopriority is generally -c 2 -n 4."

#define HELP_insmod "usage: insmod MODULE [OPTION...]\n\nLoad the module named MODULE passing options if given."

#define HELP_inotifyd "usage: inotifyd PROG FILE[:MASK] ...\n\nWhen a filesystem event matching MASK occurs to a FILE, run PROG as:\n\n  PROG EVENTS FILE [DIRFILE]\n\nIf PROG is \"-\" events are sent to stdout.\n\nThis file is:\n  a  accessed    c  modified    e  metadata change  w  closed (writable)\n  r  opened      D  deleted     M  moved            0  closed (unwritable)\n  u  unmounted   o  overflow    x  unwatchable\n\nA file in this directory is:\n  m  moved in    y  moved out   n  created          d  deleted\n\nWhen x event happens for all FILEs, inotifyd exits (after waiting for PROG)."

#define HELP_i2ctransfer "usage: i2ctransfer [-fy] BUS DESC [DATA...]...\n\nMake i2c transfers. DESC is 'r' for read or 'w' for write, followed by\nthe number of bytes to read or write, followed by '@' and a 7-bit address.\nFor any message after the first, the '@' and address can be omitted to\nreuse the previous address. A 'w' DESC must be followed by the number of\nDATA bytes that was specified in the DESC.\n\n-f	Force access to busy devices\n-v	Verbose (show messages sent, not just received)\n-y	Skip confirmation prompts (yes to all)"

#define HELP_i2cset "usage: i2cset [-fy] BUS CHIP ADDR VALUE... MODE\n\nWrite an i2c register. MODE is b for byte, w for 16-bit word, i for I2C block.\n\n-f	Force access to busy devices\n-y	Skip confirmation prompts (yes to all)"

#define HELP_i2cget "usage: i2cget [-fy] BUS CHIP [ADDR]\n\nRead an i2c register.\n\n-f	Force access to busy devices\n-y	Skip confirmation prompts (yes to all)"

#define HELP_i2cdump "usage: i2cdump [-fy] BUS CHIP\n\nDump i2c registers.\n\n-f	Force access to busy devices\n-y	Skip confirmation prompts (yes to all)"

#define HELP_i2cdetect "usage: i2cdetect [-aqry] BUS [FIRST LAST]\nusage: i2cdetect -F BUS\nusage: i2cdetect -l\n\nDetect i2c devices.\n\n-a	All addresses (0x00-0x7f rather than 0x03-0x77 or FIRST-LAST)\n-F	Show functionality\n-l	List available buses\n-q	Probe with SMBus Quick Write (default)\n-r	Probe with SMBus Read Byte\n-y	Skip confirmation prompts (yes to all)"

#define HELP_hwclock "usage: hwclock [-rswtlu] [-f FILE]\n\nGet/set the hardware clock. Default is hwclock -ruf /dev/rtc0\n\n-f	Use specified device FILE instead of /dev/rtc0 (--rtc)\n-l	Hardware clock uses localtime (--localtime)\n-r	Show hardware clock time (--show)\n-s	Set system time from hardware clock (--hctosys)\n-t	Inform kernel of non-UTC clock's timezone so it returns UTC (--systz)\n-u	Hardware clock uses UTC (--utc)\n-w	Set hardware clock from system time (--systohc)"

#define HELP_hexedit "usage: hexedit [-r] FILE\n\nHexadecimal file editor/viewer. All changes are written to disk immediately.\n\n-r	Read only (display but don't edit)\n\nKeys:\nArrows         Move left/right/up/down by one line/column\nPgUp/PgDn      Move up/down by one page\nHome/End       Start/end of line (start/end of file with ctrl)\n0-9, a-f       Change current half-byte to hexadecimal value\n^J or :        Jump (+/- for relative offset, otherwise absolute address)\n^F or /        Find string (^G/n: next, ^D/p: previous match)\nu              Undo\nx              Toggle bw/color display\nq/^C/^Q/Esc    Quit"

#define HELP_help "usage: help [-ahu] [COMMAND]\n\n-a	All commands\n-u	Usage only\n-h	HTML output\n\nShow usage information for toybox commands.\nRun \"toybox\" with no arguments for a list of available commands."

#define HELP_gpioset "usage: gpioset [-l] CHIP LINE=VALUE...\n\nSet the lines on CHIP to the given values. Use gpiofind to convert line\nnames to numbers.\n\n-l	Active low"

#define HELP_gpioget "usage: gpioget [-l] CHIP LINE...\n\nGets the values of the given lines on CHIP. Use gpiofind to convert line\nnames to numbers.\n\n-l	Active low"

#define HELP_gpioinfo "usage: gpioinfo [CHIP...]\n\nShow gpio chips' lines."

#define HELP_gpiofind "usage: gpiofind NAME\n\nShow the chip and line number for the given line name."

#define HELP_gpiodetect "usage: gpiodetect\n\nShow all gpio chips' names, labels, and number of lines."

#define HELP_getopt "usage: getopt [-aTu] [-lo OPTIONS] [-n NAME] [OPTIONS] ARG...\n\nOutputs command line with recognized OPTIONS character arguments moved to\nfront, then \"--\", then non-option arguments. Returns 1 if unknown options.\nOPTIONS followed by : take an argument, or :: for optional arguments (which\nmust be attached, ala -xblah or --long=blah).\n\n-a	Allow long options starting with a single -\n-l	Long OPTIONS (repeated or comma separated)\n-n	Command NAME for error messages\n-o	Short OPTIONS (instead of using first argument)\n-T	Test whether this is a modern getopt\n-u	Unquoted output (default if no other options set)\n\nExample:\n  $ getopt -l long:,arg:: abc command --long -b there --arg\n  --long '-b' --arg '' -- 'command' 'there'"

#define HELP_fsync "usage: fsync [-d] [FILE...]\n\nFlush disk cache for FILE(s), writing cached data to storage device.\n\n-d	Skip directory info (sync file contents only)."

#define HELP_fsfreeze "usage: fsfreeze {-f | -u} MOUNTPOINT\n\nFreeze or unfreeze a filesystem.\n\n-f	Freeze\n-u	Unfreeze"

#define HELP_freeramdisk "usage: freeramdisk [RAM device]\n\nFree all memory allocated to specified ramdisk"

#define HELP_free "usage: free [-bkmgt]\n\nDisplay the total, free and used amount of physical memory and swap space.\n\n-bkmg	Output units (default is bytes)\n-h	Human readable (K=1024)"

#define HELP_fmt "usage: fmt [-w WIDTH] [FILE...]\n\nReformat input to wordwrap at a given line length, preserving existing\nindentation level, writing to stdout.\n\n-w WIDTH	Maximum characters per line (default 75)"

#define HELP_flock "usage: flock [-sxun] fd\n\nManage advisory file locks.\n\n-s	Shared lock\n-x	Exclusive lock (default)\n-u	Unlock\n-n	Non-blocking: fail rather than wait for the lock"

#define HELP_fallocate "usage: fallocate [-o OFFSET] -l SIZE FILE\n\nTell the filesystem to allocate space for a range in a file.\n\n-l	Number of bytes in range\n-o	Start offset of range (default 0)"

#define HELP_factor "usage: factor [-hx] NUMBER...\n\nFactor integers.\n\n-h	Human readable: show repeated factors as x^n\n-x	Hexadecimal output"

#define HELP_eject "usage: eject [-stT] [DEVICE]\n\nEject DEVICE or default /dev/cdrom\n\n-s	SCSI device\n-t	Close tray\n-T	Open/close tray (toggle)"

#define HELP_unix2dos "usage: unix2dos [FILE...]\n\nConvert newline format from unix \"\\n\" to dos \"\\r\\n\".\nIf no files listed copy from stdin, \"-\" is a synonym for stdin."

#define HELP_dos2unix "usage: dos2unix [FILE...]\n\nConvert newline format from dos \"\\r\\n\" to unix \"\\n\".\nIf no files listed copy from stdin, \"-\" is a synonym for stdin."

#define HELP_devmem "usage: devmem [-f FILE] ADDR [WIDTH [DATA...]]\n\nRead/write physical addresses. WIDTH is 1, 2, 4, or 8 bytes (default 4).\nPrefix ADDR with 0x for hexadecimal, output is in same base as address.\n\n-f FILE		File to operate on (default /dev/mem)\n--no-sync	Don't open the file with O_SYNC (for cached access)\n--no-mmap	Don't mmap the file"

#define HELP_count "usage: count [-l]\n\n-l	Long output (total bytes, human readable, transfer rate, elapsed time)\n\nCopy stdin to stdout, displaying simple progress indicator to stderr."

#define HELP_clear "Clear the screen."

#define HELP_chrt "usage: chrt [-Rmofrbi] {-p PID [PRIORITY] | [PRIORITY COMMAND...]}\n\nGet/set a process' real-time scheduling policy and priority.\n\n-p	Set/query given pid (instead of running COMMAND)\n-R	Set SCHED_RESET_ON_FORK\n-m	Show min/max priorities available\n\nSet policy (default -r):\n\n  -o  SCHED_OTHER    -f  SCHED_FIFO    -r  SCHED_RR\n  -b  SCHED_BATCH    -i  SCHED_IDLE"

#define HELP_chroot "usage: chroot NEWROOT [COMMAND [ARG...]]\n\nRun command within a new root directory. If no command, run /bin/sh."

#define HELP_chcon "usage: chcon [-hRv] CONTEXT FILE...\n\nChange the SELinux security context of listed file[s].\n\n-h	Change symlinks instead of what they point to\n-R	Recurse into subdirectories\n-v	Verbose"

#define HELP_bzcat "usage: bzcat [FILE...]\n\nDecompress listed files to stdout. Use stdin if no files listed."

#define HELP_bunzip2 "usage: bunzip2 [-cftkv] [FILE...]\n\nDecompress listed files (file.bz becomes file) deleting archive file(s).\nRead from stdin if no files listed.\n\n-c	Force output to stdout\n-f	Force decompression (if FILE doesn't end in .bz, replace original)\n-k	Keep input files (-c and -t imply this)\n-t	Test integrity\n-v	Verbose"

#define HELP_blockdev "usage: blockdev --OPTION... BLOCKDEV...\n\nCall ioctl(s) on each listed block device\n\n--setro		Set read only\n--setrw		Set read write\n--getro		Get read only\n--getss		Get sector size\n--getbsz	Get block size\n--setbsz BYTES	Set block size\n--getsz		Get device size in 512-byte sectors\n--getsize	Get device size in sectors (deprecated)\n--getsize64	Get device size in bytes\n--getra		Get readahead in 512-byte sectors\n--setra SECTORS	Set readahead\n--flushbufs	Flush buffers\n--rereadpt	Reread partition table"

#define HELP_fstype "usage: fstype DEV...\n\nPrint type of filesystem on a block device or image."

#define HELP_blkid "usage: blkid [-o TYPE] [-s TAG] [-UL] DEV...\n\nPrint type, label and UUID of filesystem on a block device or image.\n\n-U	Show UUID only (or device with that UUID)\n-L	Show LABEL only (or device with that LABEL)\n-o TYPE	Output format (full, value, export)\n-s TAG	Only show matching tags (default all)"

#define HELP_blkdiscard "usage: blkdiscard [-szf] [-o OFFSET] [-l LENGTH] DEVICE\n\nDiscard device sectors (permanetly deleting data). Free space can improve\nflash performance and lifetime by wear leveling and collating data.\n(Some filesystem/driver combinations can do this automatically.)\n\n-o	Start at OFFSET (--offset, default 0)\n-l	LENGTH to discard (--length, default all)\n-s	Overwrite discarded data (--secure)\n-z	Zero-fill rather than discard (--zeroout)\n-f	Disable check for mounted filesystem (--force)\n\nOFFSET and LENGTH must be aligned to the device sector size. Default\nwithout -o/-l discards the entire device. (You have been warned.)"

#define HELP_base32 "usage: base32 [-di] [-w COLUMNS] [FILE...]\n\nEncode or decode in base32.\n\n-d	Decode\n-i	Ignore non-alphabetic characters\n-w	Wrap output at COLUMNS (default 76 or 0 for no wrap)"

#define HELP_base64 "usage: base64 [-di] [-w COLUMNS] [FILE...]\n\nEncode or decode in base64.\n\n-d	Decode\n-i	Ignore non-alphabetic characters\n-w	Wrap output at COLUMNS (default 76 or 0 for no wrap)"

#define HELP_unicode "usage: unicode CODE[-END]...\n\nConvert between Unicode code points and UTF-8, in both directions.\nCODE can be one or more characters (show U+XXXX), hex numbers\n(show character), or dash separated range."

#define HELP_ascii "usage: ascii\n\nDisplay ascii character set."

#define HELP_acpi "usage: acpi [-abctV]\n\nShow status of power sources and thermal devices.\n\n-a	Show power adapters\n-b	Show batteries\n-c	Show cooling device state\n-t	Show temperatures\n-V	Show everything"

#define HELP_xzcat "usage: xzcat [FILE...]\n\nDecompress listed files to stdout. Use stdin if no files listed."

#define HELP_vi "usage: vi [-s SCRIPT] FILE\n\nVisual text editor. Predates keyboards with standardized cursor keys.\nIf you don't know how to use it, hit the ESC key, type :q! and press ENTER.\n\n-s	run SCRIPT as if typed at keyboard (like -c \"source SCRIPT\")\n-c	run SCRIPT of ex commands\n\nThe editor is usually in one of three modes:\n\n  Hit ESC for \"vi mode\" where each key is a command.\n  Hit : for \"ex mode\" which runs command lines typed at bottom of screen.\n  Hit i (from vi mode) for \"insert mode\" where typing adds to the file.\n\nex mode commands (ESC to exit ex mode):\n\n  q   Quit (exit editor if no unsaved changes)\n  q!  Quit discarding unsaved changes\n  w   Write changed contents to file (optionally to NAME argument)\n  wq  Write to file, then quit\n\nvi mode single key commands:\n  i  switch to insert mode (until next ESC)\n  u  undo last change (can be repeated)\n  a  append (move one character right, switch to insert mode)\n  A  append (jump to end of line, switch to insert mode)\n\nvi mode commands that prompt for more data on bottom line:\n  :  switch to ex mode\n  /  search forwards for regex\n  ?  search backwards for regex\n  .  repeat last command\n\n  [count][cmd][motion]\n  cmd: c d y\n  motion: 0 b e G H h j k L l M w $ f F\n\n  [count][cmd]\n  cmd: D I J O n o p x dd yy\n\n  [cmd]\n  cmd: / ? : A a i CTRL_D CTRL_B CTRL_E CTRL_F CTRL_Y \\e \\b\n\n  [cmd]\n  \\b \\e \\n 'set list' 'set nolist' d $ % g v"

#define HELP_userdel "usage: userdel [-r] USER\nusage: deluser [-r] USER\n\nDelete USER from the SYSTEM\n\n-r	remove home directory"

#define HELP_useradd "usage: useradd [-SDH] [-h DIR] [-s SHELL] [-G GRP] [-g NAME] [-u UID] USER [GROUP]\n\nCreate new user, or add USER to GROUP\n\n-D       Don't assign a password\n-g NAME  Real name\n-G GRP   Add user to existing group\n-h DIR   Home directory\n-H       Don't create home directory\n-s SHELL Login shell\n-S       Create a system user\n-u UID   User id"

#define HELP_traceroute "usage: traceroute [-46FUIldnvr] [-f 1ST_TTL] [-m MAXTTL] [-p PORT] [-q PROBES]\n[-s SRC_IP] [-t TOS] [-w WAIT_SEC] [-g GATEWAY] [-i IFACE] [-z PAUSE_MSEC] HOST [BYTES]\n\ntraceroute6 [-dnrv] [-m MAXTTL] [-p PORT] [-q PROBES][-s SRC_IP] [-t TOS] [-w WAIT_SEC]\n  [-i IFACE] HOST [BYTES]\n\nTrace the route to HOST\n\n-4,-6 Force IP or IPv6 name resolution\n-F    Set the don't fragment bit (supports IPV4 only)\n-U    Use UDP datagrams instead of ICMP ECHO (supports IPV4 only)\n-I    Use ICMP ECHO instead of UDP datagrams (supports IPV4 only)\n-l    Display the TTL value of the returned packet (supports IPV4 only)\n-d    Set SO_DEBUG options to socket\n-n    Print numeric addresses\n-v    verbose\n-r    Bypass routing tables, send directly to HOST\n-m    Max time-to-live (max number of hops)(RANGE 1 to 255)\n-p    Base UDP port number used in probes(default 33434)(RANGE 1 to 65535)\n-q    Number of probes per TTL (default 3)(RANGE 1 to 255)\n-s    IP address to use as the source address\n-t    Type-of-service in probe packets (default 0)(RANGE 0 to 255)\n-w    Time in seconds to wait for a response (default 3)(RANGE 0 to 86400)\n-g    Loose source route gateway (8 max) (supports IPV4 only)\n-z    Pause Time in ms (default 0)(RANGE 0 to 86400) (supports IPV4 only)\n-f    Start from the 1ST_TTL hop (instead from 1)(RANGE 1 to 255) (supports IPV4 only)\n-i    Specify a network interface to operate with"

#define HELP_tr "usage: tr [-cdst] SET1 [SET2]\n\nTranslate, squeeze, or delete characters from stdin, writing to stdout\n\n-c/-C  Take complement of SET1\n-d     Delete input characters coded SET1\n-s     Squeeze multiple output characters of SET2 into one character\n-t     Truncate SET1 to length of SET2"

#define HELP_tftpd "usage: tftpd [-cr] [-u USER] [DIR]\n\nTransfer file from/to tftp server.\n\n-r	read only\n-c	Allow file creation via upload\n-u	run as USER\n-l	Log to syslog (inetd mode requires this)"

#define HELP_tftp "usage: tftp [OPTIONS] HOST [PORT]\n\nTransfer file from/to tftp server.\n\n-l FILE Local FILE\n-r FILE Remote FILE\n-g    Get file\n-p    Put file\n-b SIZE Transfer blocks of SIZE octets(8 <= SIZE <= 65464)"

#define HELP_telnetd "Handle incoming telnet connections\n\n-l LOGIN  Exec LOGIN on connect\n-f ISSUE_FILE Display ISSUE_FILE instead of /etc/issue\n-K Close connection as soon as login exits\n-p PORT   Port to listen on\n-b ADDR[:PORT]  Address to bind to\n-F Run in foreground\n-i Inetd mode\n-w SEC    Inetd 'wait' mode, linger time SEC\n-S Log to syslog (implied by -i or without -F and -w)"

#define HELP_telnet "usage: telnet HOST [PORT]\n\nConnect to telnet server."

#define HELP_tcpsvd "usage: tcpsvd [-hEv] [-c N] [-C N[:MSG]] [-b N] [-u User] [-l Name] IP Port Prog\nusage: udpsvd [-hEv] [-c N] [-u User] [-l Name] IP Port Prog\n\nCreate TCP/UDP socket, bind to IP:PORT and listen for incoming connection.\nRun PROG for each connection.\n\nIP            IP to listen on, 0 = all\nPORT          Port to listen on\nPROG ARGS     Program to run\n-l NAME       Local hostname (else looks up local hostname in DNS)\n-u USER[:GRP] Change to user/group after bind\n-c N          Handle up to N (> 0) connections simultaneously\n-b N          (TCP Only) Allow a backlog of approximately N TCP SYNs\n-C N[:MSG]    (TCP Only) Allow only up to N (> 0) connections from the same IP\n              New connections from this IP address are closed\n              immediately. MSG is written to the peer before close\n-h            Look up peer's hostname\n-E            Don't set up environment variables\n-v            Verbose"

#define HELP_syslogd "usage: syslogd  [-a socket] [-O logfile] [-f config file] [-m interval]\n                [-p socket] [-s SIZE] [-b N] [-R HOST] [-l N] [-nSLKD]\n\nSystem logging utility\n\n-a      Extra unix socket for listen\n-O FILE Default log file <DEFAULT: /var/log/messages>\n-f FILE Config file <DEFAULT: /etc/syslog.conf>\n-p      Alternative unix domain socket <DEFAULT : /dev/log>\n-n      Avoid auto-backgrounding\n-S      Smaller output\n-m MARK interval <DEFAULT: 20 minutes> (RANGE: 0 to 71582787)\n-R HOST Log to IP or hostname on PORT (default PORT=514/UDP)\"\n-L      Log locally and via network (default is network only if -R)\"\n-s SIZE Max size (KB) before rotation (default:200KB, 0=off)\n-b N    rotated logs to keep (default:1, max=99, 0=purge)\n-K      Log to kernel printk buffer (use dmesg to read it)\n-l N    Log only messages more urgent than prio(default:8 max:8 min:1)\n-D      Drop duplicates"

#define HELP_sulogin "usage: sulogin [-t time] [tty]\n\nSingle User Login.\n-t	Default Time for Single User Login"

#define HELP_stty "usage: stty [-ag] [-F device] SETTING...\n\nGet/set terminal configuration.\n\n-F	Open device instead of stdin\n-a	Show all current settings (default differences from \"sane\")\n-g	Show all current settings usable as input to stty\n\nSpecial characters (syntax ^c or undef): intr quit erase kill eof eol eol2\nswtch start stop susp rprnt werase lnext discard\n\nControl/input/output/local settings as shown by -a, '-' prefix to disable\n\nCombo settings: cooked/raw, evenp/oddp/parity, nl, ek, sane\n\nN	set input and output speed (ispeed N or ospeed N for just one)\ncols N	set number of columns\nrows N	set number of rows\nline N	set line discipline\nmin N	set minimum chars per read\ntime N	set read timeout\nspeed	show speed only\nsize	show size only"

#define HELP_strace "usage: strace [-fv] [-p PID] [-s NUM] COMMAND [ARGS...]\n\nTrace systems calls made by a process.\n\n-s	String length limit.\n-v	Dump all of large structs/arrays."

#define HELP_wait "usage: wait [-n] [ID...]\n\nWait for background processes to exit, returning its exit code.\nID can be PID or job, with no IDs waits for all backgrounded processes.\n\n-n	Wait for next process to exit"

#define HELP_source "usage: source FILE [ARGS...]\n\nRead FILE and execute commands. Any ARGS become positional parameters."

#define HELP_shift "usage: shift [N]\n\nSkip N (default 1) positional parameters, moving $1 and friends along the list.\nDoes not affect $0."

#define HELP_return "usage: return [#]\n\nReturn from function/source with specified value or last command's exit val."

#define HELP_local "usage: local [NAME[=VALUE]...]\n\nCreate a local variable that lasts until return from this function.\nWith no arguments lists local variables in current function context.\nTODO: implement \"declare\" options."

#define HELP_jobs "usage: jobs [-lnprs] [%JOB | -x COMMAND...]\n\nList running/stopped background jobs.\n\n-l Include process ID in list\n-n Show only new/changed processes\n-p Show process IDs only\n-r Show running processes\n-s Show stopped processes"

#define HELP_export "usage: export [-n] [NAME[=VALUE]...]\n\nMake variables available to child processes. NAME exports existing local\nvariable(s), NAME=VALUE sets and exports.\n\n-n	Unexport. Turn listed variable(s) into local variables.\n\nWith no arguments list exported variables/attributes as \"declare\" statements."

#define HELP_exec "usage: exec [-cl] [-a NAME] COMMAND...\n\n-a	set argv[0] to NAME\n-c	clear environment\n-l	prepend - to argv[0]"

#define HELP_eval "usage: eval COMMAND...\n\nExecute (combined) arguments as a shell command."

#define HELP_unset "usage: unset [-fvn] NAME...\n\n-f	NAME is a function\n-v	NAME is a variable\n-n	dereference NAME and unset that"

#define HELP_set "usage: set [+a] [+o OPTION] [VAR...]\n\nSet variables and shell attributes. Use + to disable and - to enable.\nNAME=VALUE arguments assign to the variable, any leftovers set $1, $2...\nWith no arguments, prints current variables.\n\n-f	NAME is a function\n-v	NAME is a variable\n-n	don't follow name reference\n\nOPTIONs:\n  history - enable command history"

#define HELP_exit "usage: exit [status]\n\nExit shell.  If no return value supplied on command line, use value\nof most recent command, or 0 if none."

#define HELP_declare "usage: declare [-pAailunxr] [NAME...]\n\nSet or print variable attributes and values.\n\n-p	Print variables instead of setting\n-A	Associative array\n-a	Indexed array\n-i	Integer\n-l	Lower case\n-n	Name reference (symlink)\n-r	Readonly\n-u	Uppercase\n-x	Export"

#define HELP_continue "usage: continue [N]\n\nStart next entry in for/while/until loop (or Nth outer loop, default 1)."

#define HELP_cd "usage: cd [-PL] [-] [path]\n\nChange current directory. With no arguments, go $HOME. Sets $OLDPWD to\nprevious directory: cd - to return to $OLDPWD.\n\n-P	Physical path: resolve symlinks in path\n-L	Local path: .. trims directories off $PWD (default)"

#define HELP_break "usage: break [N]\n\nEnd N levels of for/while/until loop immediately (default 1)."

#define HELP_sh "usage: sh [-c command] [script]\n\nCommand shell.  Runs a shell script, or reads input interactively\nand responds to it. Roughly compatible with \"bash\". Run \"help\" for\nlist of built-in commands.\n\n-c	command line to execute\n-i	interactive mode (default when STDIN is a tty)\n-s	don't run script (args set $* parameters but read commands from stdin)\n\nCommand shells parse each line of input (prompting when interactive), perform\nvariable expansion and redirection, execute commands (spawning child processes\nand background jobs), and perform flow control based on the return code.\n\nParsing:\n  syntax errors\n\nInteractive prompts:\n  line continuation\n\nVariable expansion:\n  Note: can cause syntax errors at runtime\n\nRedirection:\n  HERE documents (parsing)\n  Pipelines (flow control and job control)\n\nRunning commands:\n  process state\n  builtins\n    cd [[ ]] (( ))\n    ! : [ # TODO: help for these?\n    true false help echo kill printf pwd test\n  child processes\n\nJob control:\n  &    Background process\n  Ctrl-C kill process\n  Ctrl-Z suspend process\n  bg fg jobs kill\n\nFlow control:\n;    End statement (same as newline)\n&    Background process (returns true unless syntax error)\n&&   If this fails, next command fails without running\n||   If this succeeds, next command succeeds without running\n|    Pipelines! (Can of worms...)\nfor {name [in...]}|((;;)) do; BODY; done\nif TEST; then BODY; fi\nwhile TEST; do BODY; done\ncase a in X);; esac\n[[ TEST ]]\n((MATH))\n\nJob control:\n&    Background process\nCtrl-C kill process\nCtrl-Z suspend process\nbg fg jobs kill"

#define HELP_route "usage: route [-ne] [-A [inet|inet6]] [add|del TARGET [OPTIONS]]\n\nDisplay, add or delete network routes in the \"Forwarding Information Base\",\nwhich send packets out a network interface to an address.\n\n-n	Show numerical addresses (no DNS lookups)\n-e	display netstat fields\n\nAssigning an address to an interface automatically creates an appropriate\nnetwork route (\"ifconfig eth0 10.0.2.15/8\" does \"route add 10.0.0.0/8 eth0\"\nfor you), although some devices (such as loopback) won't show it in the\ntable. For machines more than one hop away, you need to specify a gateway\n(ala \"route add default gw 10.0.2.2\").\n\nThe address \"default\" is a wildcard address (0.0.0.0/0) matching all\npackets without a more specific route.\n\nAvailable OPTIONS include:\nreject   - blocking route (force match failure)\ndev NAME - force matching packets out this interface (ala \"eth0\")\nnetmask  - old way of saying things like ADDR/24\ngw ADDR  - forward packets to gateway ADDR"

#define HELP_more "usage: more [FILE...]\n\nView FILE(s) (or stdin) one screenfull at a time."

#define HELP_modprobe "usage: modprobe [-alrqvsDb] [-d DIR] MODULE [symbol=value][...]\n\nmodprobe utility - inserts modules and dependencies.\n\n-a  Load multiple MODULEs\n-b  Apply blacklist to module names too\n-D  Show dependencies\n-d  Load modules from DIR, option may be used multiple times\n-l  List (MODULE is a pattern)\n-q  Quiet\n-r  Remove MODULE (stacks) or do autoclean\n-s  Log to syslog\n-v  Verbose"

#define HELP_mdev_conf "The mdev config file (/etc/mdev.conf) contains lines that look like:\nhd[a-z][0-9]* 0:3 660\n(sd[a-z]) root:disk 660 =usb_storage\n\nEach line must contain three whitespace separated fields. The first\nfield is a regular expression matching one or more device names,\nthe second and third fields are uid:gid and file permissions for\nmatching devices. Fourth field is optional. It could be used to change\ndevice name (prefix '='), path (prefix '=' and postfix '/') or create a\nsymlink (prefix '>')."

#define HELP_mdev "usage: mdev [-s]\n\nCreate devices in /dev using information from /sys.\n\n-s	Scan all entries in /sys to populate /dev"

#define HELP_man "usage: man [-M PATH] [-k STRING] | [SECTION] COMMAND\n\nRead manual page for system command.\n\n-k	List pages with STRING in their short description\n-M	Override $MANPATH\n\nMan pages are divided into 8 sections:\n1 commands      2 system calls  3 library functions  4 /dev files\n5 file formats  6 games         7 miscellaneous      8 system management\n\nSections are searched in the order 1 8 3 2 5 4 6 7 unless you specify a\nsection. Each section has a page called \"intro\", and there's a global\nintroduction under \"man-pages\"."

#define HELP_lsof "usage: lsof [-lt] [-p PID1,PID2,...] [FILE...]\n\nList all open files belonging to all active processes, or processes using\nlisted FILE(s).\n\n-l	list uids numerically\n-p	for given comma-separated pids only (default all pids)\n-t	terse (pid only) output"

#define HELP_last "usage: last [-W] [-f FILE]\n\nShow listing of last logged in users.\n\n-W      Display the information without host-column truncation\n-f FILE Read from file FILE instead of /var/log/wtmp"

#define HELP_klogd "usage: klogd [-n] [-c PRIORITY]\n\nForward messages from the kernel ring buffer (read by dmesg) to syslogd.\n\n-c	Print to console messages more urgent than PRIORITY (1-8)\n-n	Run in foreground\n-s	Use syscall instead of /proc"

#define HELP_ipcs "usage: ipcs [[-smq] -i shmid] | [[-asmq] [-tcplu]]\n\n-i Show specific resource\nResource specification:\n-a All (default)\n-m Shared memory segments\n-q Message queues\n-s Semaphore arrays\nOutput format:\n-c Creator\n-l Limits\n-p Pid\n-t Time\n-u Summary"

#define HELP_ipcrm "usage: ipcrm [ [-q msqid] [-m shmid] [-s semid]\n          [-Q msgkey] [-M shmkey] [-S semkey] ... ]\n\n-mM Remove memory segment after last detach\n-qQ Remove message queue\n-sS Remove semaphore"

#define HELP_ip "usage: ip [ OPTIONS ] OBJECT { COMMAND }\n\nShow / manipulate routing, devices, policy routing and tunnels.\n\nwhere OBJECT := {address | link | route | rule | tunnel}\nOPTIONS := { -f[amily] { inet | inet6 | link } | -o[neline] }"

#define HELP_init "usage: init\n\nSystem V style init.\n\nFirst program to run (as PID 1) when the system comes up, reading\n/etc/inittab to determine actions."

#define HELP_hd "usage: hd [FILE...]\n\nDisplay file(s) in cannonical hex+ASCII format."

#define HELP_hexdump "usage: hexdump [-bcCdovx] [-n LEN] [-s SKIP] [FILE...]\n\nDump file(s) in hexadecimal format.\n\n-n LEN	Show LEN bytes of output\n-s SKIP	Skip bytes of input\n-v	Verbose (don't combine identical lines)\n\nDisplay type:\n-b One byte octal   -c One byte character -C Canonical (hex + ASCII)\n-d Two byte decimal -o Two byte octal     -x Two byte hexadecimal (default)"

#define HELP_groupdel "usage: groupdel [USER] GROUP\n\nDelete a group or remove a user from a group"

#define HELP_groupadd "usage: groupadd [-S] [-g GID] [USER] GROUP\n\nAdd a user to a group, or create a new group.\n\n-g GID	Group id\n-R	Operate within chroot\n-S	Create a system group"

#define HELP_gitcheckout "usage: gitcheckout <branch>\nA minimal git checkout."

#define HELP_gitfetch "usage: gitfetch\nA minimal git fetch."

#define HELP_gitremote "usage: gitremote URL\nA minimal git remote add origin."

#define HELP_gitinit "usage: gitinit NAME\nA minimal git init."

#define HELP_gitclone "usage: gitclone URL\nA minimal git clone."

#define HELP_gitcompat "Enable git compatible repos instead of minimal clone downloader."

#define HELP_getty "usage: getty [OPTIONS] BAUD_RATE[,BAUD_RATE]... TTY [TERMTYPE]\n\nWait for a modem to dial into serial port, adjust baud rate, call login.\n\n-h    Enable hardware RTS/CTS flow control\n-L    Set CLOCAL (ignore Carrier Detect state)\n-m    Get baud rate from modem's CONNECT status message\n-n    Don't prompt for login name\n-w    Wait for CR or LF before sending /etc/issue\n-i    Don't display /etc/issue\n-f ISSUE_FILE  Display ISSUE_FILE instead of /etc/issue\n-l LOGIN  Invoke LOGIN instead of /bin/login\n-t SEC    Terminate after SEC if no login name is read\n-I INITSTR  Send INITSTR before anything else\n-H HOST    Log HOST into the utmp file as the hostname"

#define HELP_getfattr "usage: getfattr [-d] [-h] [-n NAME] FILE...\n\nRead POSIX extended attributes.\n\n-d	Show values as well as names\n-h	Do not dereference symbolic links\n-n	Show only attributes with the given name\n--only-values	Don't show names"

#define HELP_fsck "usage: fsck [-ANPRTV] [-C FD] [-t FSTYPE] [FS_OPTS] [BLOCKDEV]...\n\nCheck and repair filesystems\n\n-A      Walk /etc/fstab and check all filesystems\n-N      Don't execute, just show what would be done\n-P      With -A, check filesystems in parallel\n-R      With -A, skip the root filesystem\n-T      Don't show title on startup\n-V      Verbose\n-C n    Write status information to specified file descriptor\n-t TYPE List of filesystem types to check"

#define HELP_fdisk "usage: fdisk [-lu] [-C CYLINDERS] [-H HEADS] [-S SECTORS] [-b SECTSZ] DISK\n\nChange partition table\n\n-u            Start and End are in sectors (instead of cylinders)\n-l            Show partition table for each DISK, then exit\n-b size       sector size (512, 1024, 2048 or 4096)\n-C CYLINDERS  Set number of cylinders/heads/sectors\n-H HEADS\n-S SECTORS"

#define HELP_expr "usage: expr ARG1 OPERATOR ARG2...\n\nEvaluate expression and print result. For example, \"expr 1 + 2\" prints \"3\".\n\nThe supported operators are (grouped from highest to lowest priority):\n\n  ( )    :    * / %    + -    != <= < >= > =    &    |\n\nEach constant and operator must be a separate command line argument.\nAll operators are infix, requiring a value on each side of the operator.\nOperators of the same priority are evaluated left to right. Parentheses\nelevate the priority of expression they contain. The & and | operators\nare logical (not bitwise).\n\nAll operators yield integers, and most operators expect integer arguments.\nComparisons may alphabetically compare strings, logical operators treat a\nblank string as false and nonblank as true, and the regex operator\n(str : pattern) yields the initial number of matching bytes. (So\n\"abc : ab\" is 2, but \"abc : bc\" is 0.)\n\nCalling expr from a command shell requires a lot of \\( or '*' escaping\nto avoid interpreting shell control characters, vs the shell's \"$((1+6/3))\"."

#define HELP_dumpleases "usage: dumpleases [-r|-a] [-f LEASEFILE]\n\nDisplay DHCP leases granted by udhcpd\n-f FILE,  Lease file\n-r        Show remaining time\n-a        Show expiration time"

#define HELP_diff "usage: diff [-abBdiNqrTstw] [-L LABEL] [-S FILE] [-U LINES] [-F REGEX ] FILE1 FILE2\n\n-a	Treat all files as text\n-b	Ignore changes in the amount of whitespace\n-B	Ignore changes whose lines are all blank\n-d	Try hard to find a smaller set of changes\n-F 	Show the most recent line matching the regex\n-i	Ignore case differences\n-L	Use LABEL instead of the filename in the unified header\n-N	Treat absent files as empty\n-q	Output only whether files differ\n-r	Recurse\n-S	Start with FILE when comparing directories\n-s	Report when two files are the same\n-T	Make tabs line up by prefixing a tab when necessary\n-t	Expand tabs to spaces in output\n-u	Unified diff\n-U	Output LINES lines of context\n-w	Ignore all whitespace\n\n--color     Color output   --strip-trailing-cr   Strip '\\r' from input lines\n--no-dereference Don't follow symbolic links\n--TYPE-line-format=FORMAT  Display TYPE (unchanged/old/new) lines using FORMAT\n  FORMAT uses printf integer escapes (ala %-2.4x) followed by LETTER: FELMNn\nSupported format specifiers are:\n* %l, the contents of the line, without the trailing newline\n* %L, the contents of the line, including the trailing newline\n* %%, the character '%'"

#define HELP_dhcpd "usage: dhcpd [-46fS] [-i IFACE] [-P N] [CONFFILE]\n\n -f    Run in foreground\n -i Interface to use\n -S    Log to syslog too\n -P N  Use port N (default ipv4 67, ipv6 547)\n -4, -6    Run as a DHCPv4 or DHCPv6 server"

#define HELP_dhcp6 "usage: dhcp6 [-fbnqvR] [-i IFACE] [-r IP] [-s PROG] [-p PIDFILE]\n\nConfigure network dynamically using DHCP.\n\n-i Interface to use (default eth0)\n-p Create pidfile\n-s Run PROG at DHCP events\n-t Send up to N Solicit packets\n-T Pause between packets (default 3 seconds)\n-A Wait N seconds after failure (default 20)\n-f Run in foreground\n-b Background if lease is not obtained\n-n Exit if lease is not obtained\n-q Exit after obtaining lease\n-R Release IP on exit\n-S Log to syslog too\n-r Request this IP address\n-v Verbose\n\nSignals:\nUSR1  Renew current lease\nUSR2  Release current lease"

#define HELP_dhcp "usage: dhcp [-fbnqvoCRB] [-i IFACE] [-r IP] [-s PROG] [-p PIDFILE]\n            [-H HOSTNAME] [-V VENDOR] [-x OPT:VAL] [-O OPT]\n\n     Configure network dynamically using DHCP.\n\n   -i Interface to use (default eth0)\n   -p Create pidfile\n   -s Run PROG at DHCP events (default /usr/share/dhcp/default.script)\n   -B Request broadcast replies\n   -t Send up to N discover packets\n   -T Pause between packets (default 3 seconds)\n   -A Wait N seconds after failure (default 20)\n   -f Run in foreground\n   -b Background if lease is not obtained\n   -n Exit if lease is not obtained\n   -q Exit after obtaining lease\n   -R Release IP on exit\n   -S Log to syslog too\n   -a Use arping to validate offered address\n   -O Request option OPT from server (cumulative)\n   -o Don't request any options (unless -O is given)\n   -r Request this IP address\n   -x OPT:VAL  Include option OPT in sent packets (cumulative)\n   -F Ask server to update DNS mapping for NAME\n   -H Send NAME as client hostname (default none)\n   -V VENDOR Vendor identifier (default 'toybox VERSION')\n   -C Don't send MAC as client identifier\n   -v Verbose\n\n   Signals:\n   USR1  Renew current lease\n   USR2  Release current lease"

#define HELP_csplit "usage: csplit [-ks] [-f PREFIX] [-n INTEGER] file arg...\n\nSplit files into multiple files based on list of rules\n\n-k	Does not delete Files on error\n-s	No file output size messages\n-f [PREFIX] Use [PREFIX] as filename prefix instead of \"xx\"\n-n [INTEGER] Make all filename numbers [INTEGER] characters long\n\nValid Rules:\n/regexp/[INTEGER] Break file before line that regexp matches,\n%regexp%[INTEGER] Exclude untill line matches regexp\nIf a offset is specified for these rules, the break will happen [INTEGER]\nlines after the regexp match\nif a offset is specified, it will break at [INTEGER] lines after the offset\n[INTEGER] Break file at line before [INTEGER]\n{INTEGER} Repeat Previous Pattern INTEGER Number of times if INTEGER is *\nThe pattern repeats forever"

#define HELP_crontab "usage: crontab [-u user] FILE\n               [-u user] [-e | -l | -r]\n               [-c dir]\n\nFiles used to schedule the execution of programs.\n\n-c crontab dir\n-e edit user's crontab\n-l list user's crontab\n-r delete user's crontab\n-u user\nFILE Replace crontab by FILE ('-': stdin)"

#define HELP_crond "usage: crond [-fbS] [-l N] [-d N] [-L LOGFILE] [-c DIR]\n\nA daemon to execute scheduled commands.\n\n-b Background (default)\n-c crontab dir\n-d Set log level, log to stderr\n-f Foreground\n-l Set log level. 0 is the most verbose, default 8\n-S Log to syslog (default)\n-L Log to file"

#define HELP_chsh "usage: chsh [-s SHELL] [-R CHROOT_DIR] [USER]\n\nChange user's login shell.\n\n-s	Use SHELL instead of prompting\n-R	Act on CHROOT_DIR instead of host\n\nNon-root users can only change their own shell to one listed in /etc/shells."

#define HELP_brctl "usage: brctl COMMAND [BRIDGE [INTERFACE]]\n\nManage ethernet bridges\n\nCommands:\nshow                  Show a list of bridges\naddbr BRIDGE          Create BRIDGE\ndelbr BRIDGE          Delete BRIDGE\naddif BRIDGE IFACE    Add IFACE to BRIDGE\ndelif BRIDGE IFACE    Delete IFACE from BRIDGE\nsetageing BRIDGE TIME Set ageing time\nsetfd BRIDGE TIME     Set bridge forward delay\nsethello BRIDGE TIME  Set hello time\nsetmaxage BRIDGE TIME Set max message age\nsetpathcost BRIDGE PORT COST   Set path cost\nsetportprio BRIDGE PORT PRIO   Set port priority\nsetbridgeprio BRIDGE PRIO      Set bridge priority\nstp BRIDGE [1/yes/on|0/no/off] STP on/off"

#define HELP_bootchartd "usage: bootchartd {start [PROG ARGS]}|stop|init\n\nRecord boot chart data into /var/log/bootlog.tgz\n\nstart: start background logging; with PROG, run PROG,\n       then kill logging with SIGUSR1\nstop:  send SIGUSR1 to all bootchartd processes\ninit:  start background logging; stop when getty/xdm is seen\n      (for init scripts)\n\nUnder PID 1: as init, then exec $bootchart_init, /init, /sbin/init"

#define HELP_bc "usage: bc [-ilqsw] [file ...]\n\nbc is a command-line calculator with a Turing-complete language.\n\noptions:\n\n  -i  --interactive  force interactive mode\n  -l  --mathlib      use predefined math routines:\n\n                     s(expr)  =  sine of expr in radians\n                     c(expr)  =  cosine of expr in radians\n                     a(expr)  =  arctangent of expr, returning radians\n                     l(expr)  =  natural log of expr\n                     e(expr)  =  raises e to the power of expr\n                     j(n, x)  =  Bessel function of integer order n of x\n\n  -q  --quiet        don't print version and copyright\n  -s  --standard     error if any non-POSIX extensions are used\n  -w  --warn         warn if any non-POSIX extensions are used"

#define HELP_awk "usage:  awk [-F sepstring] [-v assignment]... program [argument...]\n  or:\n        awk [-F sepstring] -f progfile [-f progfile]... [-v assignment]...\n              [argument...]\n  also:\n  -b : count bytes, not characters (experimental)\n  -c : compile only, do not run"

#define HELP_arping "usage: arping [-fqbDUA] [-c CNT] [-w TIMEOUT] [-I IFACE] [-s SRC_IP] DST_IP\n\nSend ARP requests/replies\n\n-f         Quit on first ARP reply\n-q         Quiet\n-b         Keep broadcasting, don't go unicast\n-D         Duplicated address detection mode\n-U         Unsolicited ARP mode, update your neighbors\n-A         ARP answer mode, update your neighbors\n-c N       Stop after sending N ARP requests\n-w TIMEOUT Time to wait for ARP reply, seconds\n-I IFACE   Interface to use (default eth0)\n-s SRC_IP  Sender IP address\nDST_IP     Target IP address"

#define HELP_arp "usage: arp\n[-vn] [-H HWTYPE] [-i IF] -a [HOSTNAME]\n[-v]              [-i IF] -d HOSTNAME [pub]\n[-v]  [-H HWTYPE] [-i IF] -s HOSTNAME HWADDR [temp]\n[-v]  [-H HWTYPE] [-i IF] -s HOSTNAME HWADDR [netmask MASK] pub\n[-v]  [-H HWTYPE] [-i IF] -Ds HOSTNAME IFACE [netmask MASK] pub\n\nManipulate ARP cache.\n\n-a	Display (all) hosts\n-s	Set new ARP entry\n-d	Delete a specified entry\n-v	Verbose\n-n	Don't resolve names\n-i IFACE	Network interface\n-D	Read <hwaddr> from given device\n-A,-p AF	Protocol family\n-H HWTYPE	Hardware address type"

#define HELP_xargs "usage: xargs [-0Pprt] [-snE STR] COMMAND...\n\nRun command line one or more times, appending arguments from stdin.\n\nIf COMMAND exits with 255, don't launch another even if arguments remain.\n\n-0	Each argument is NULL terminated, no whitespace or quote processing\n-E	Stop at line matching string\n-n	Max number of arguments per command\n-o	Open tty for COMMAND's stdin (default /dev/null)\n-P	Parallel processes (default 1)\n-p	Prompt for y/n from tty before running each command\n-r	Don't run with empty input (otherwise always run command once)\n-s	Size in bytes per command line\n-t	Trace, print command line to stderr"

#define HELP_who "usage: who\n\nPrint information about logged in users."

#define HELP_wc "usage: wc [-Llwcm] [FILE...]\n\nCount lines, words, and characters in input.\n\n-L	Show max line length\n-l	Show lines\n-w	Show words\n-c	Show bytes\n-m	Show characters\n\nBy default outputs lines, words, bytes, and filename for each\nargument (or from stdin if none). Displays only either bytes\nor characters."

#define HELP_uuencode "usage: uuencode [-m] [INFILE] ENCODE_FILENAME\n\nUuencode stdin (or INFILE) to stdout, with ENCODE_FILENAME in the output.\n\n-m	Base64"

#define HELP_uudecode "usage: uudecode [-o OUTFILE] [INFILE]\n\nDecode file from stdin (or INFILE).\n\n-o	Write to OUTFILE instead of filename in header"

#define HELP_unlink "usage: unlink FILE\n\nDelete one file."

#define HELP_uniq "usage: uniq [-cduiz] [-w MAXCHARS] [-f FIELDS] [-s CHAR] [INFILE [OUTFILE]]\n\nReport or filter out repeated lines in a file\n\n-c	Show counts before each line\n-d	Show only lines that are repeated\n-u	Show only lines that are unique\n-i	Ignore case when comparing lines\n-z	Lines end with \\0 not \\n\n-w	Compare maximum X chars per line\n-f	Ignore first X fields\n-s	Ignore first X chars"

#define HELP_uname "usage: uname [-asnrvmo]\n\nPrint system information.\n\n-s	System name\n-n	Network (domain) name\n-r	Kernel Release number\n-v	Kernel Version\n-m	Machine (hardware) name\n-a	All of the above (in order)\n\n-o	Userspace type"

#define HELP_arch "usage: arch\n\nPrint machine (hardware) name, same as uname -m."

#define HELP_ulimit "usage: ulimit [-P PID] [-SHRacdefilmnpqrstuv] [LIMIT]\n\nPrint or set resource limits for process number PID. If no LIMIT specified\n(or read-only -ap selected) display current value (sizes in bytes).\nDefault is ulimit -P $PPID -Sf\" (show soft filesize of your shell).\n\n-P  PID to affect (default $PPID)  -a  Show all limits\n-S  Set/show soft limit            -H  Set/show hard (maximum) limit\n\n-c  Core file size (blocks)        -d  Process data segment (KiB)\n-e  Max scheduling priority        -f  File size (KiB)\n-i  Pending signal count           -l  Locked memory (KiB)\n-m  Resident Set Size (KiB)        -n  Number of open files\n-p  Pipe buffer (512 bytes)        -q  POSIX message queues\n-r  Max realtime priority          -R  Realtime latency (us)\n-s  Stack size (KiB)               -t  Total CPU time (s)\n-u  Maximum processes (this UID)   -v  Virtual memory size (KiB)"

#define HELP_tty "usage: tty [-s]\n\nShow filename of terminal connected to stdin. If none print \"not a tty\"\nand exit with nonzero status.\n\n-s	Silent, exit code only"

#define HELP_tsort "usage: tsort [FILE]\n\nTopological sort dependency resolver.\n\nRead pairs of input strings indicating before/after dependency relationships\nand find an ordering that respects all dependencies. On success output each\nstring once to stdout, on failure print error and output cycle pairs."

#define HELP_true "usage: true\n\nReturn zero."

#define HELP_touch "usage: touch [-amch] [-d DATE] [-t TIME] [-r FILE] FILE...\n\nUpdate the access and modification times of each FILE to the current time.\n\n-a	Change access time\n-m	Change modification time\n-c	Don't create file\n-h	Change symlink\n-d	Set time to DATE (in YYYY-MM-DDThh:mm:SS[.frac][tz] format)\n-t	Set time to TIME (in [[CC]YY]MMDDhhmm[.ss][frac] format)\n-r	Set time same as reference FILE"

#define HELP_time "usage: time [-pv] COMMAND...\n\nRun command line and report real, user, and system time elapsed in seconds.\n(real = clock on the wall, user = cpu used by command's code,\nsystem = cpu used by OS on behalf of command.)\n\n-p	POSIX format output\n-v	Verbose"

#define HELP_test "usage: test [-bcdefghkLprSsuwx PATH] [-nz STRING] [-t FD] [X ?? Y]\n\nReturn true or false by performing tests. No arguments is false, one argument\nis true if not empty string.\n\n--- Tests with a single argument (after the option):\nPATH is/has:\n  -b  block device   -f  regular file   -p  fifo           -u  setuid bit\n  -c  char device    -g  setgid         -r  readable       -w  writable\n  -d  directory      -h  symlink        -S  socket         -x  executable\n  -e  exists         -L  symlink        -s  nonzero size   -k  sticky bit\nSTRING is:\n  -n  nonzero size   -z  zero size\nFD (integer file descriptor) is:\n  -t  a TTY\n\n--- Tests with one argument on each side of an operator:\nTwo strings:\n  =  are identical   !=  differ         =~  string matches regex\nAlphabetical sort:\n  <  first is lower  >   first higher\nTwo integers:\n  -eq  equal         -gt  first > second    -lt  first < second\n  -ne  not equal     -ge  first >= second   -le  first <= second\nTwo files:\n  -ot  Older mtime   -nt  Newer mtime       -ef  same dev/inode\n\n--- Modify or combine tests:\n  ! EXPR     not (swap true/false)   EXPR -a EXPR    and (are both true)\n  ( EXPR )   evaluate this first     EXPR -o EXPR    or (is either true)"

#define HELP_tee "usage: tee [-ai] [FILE...]\n\nCopy stdin to each listed file, and also to stdout.\nFilename \"-\" is a synonym for stdout.\n\n-a	Append to files\n-i	Ignore SIGINT"

#define HELP_tar "usage: tar [-cxt] [-fvohmjkOS] [-XTCf NAME] [--selinux] [FILE...]\n\nCreate, extract, or list files in a .tar (or compressed t?z) file.\n\nOptions:\nc  Create                x  Extract               t  Test (list)\nf  tar FILE (default -)  C  Change to DIR first   v  Verbose display\nJ  xz compression        j  bzip2 compression     z  gzip compression\no  Ignore owner          h  Follow symlinks       m  Ignore mtime\nO  Extract to stdout     X  exclude names in FILE T  include names in FILE\ns  Sort dirs (--sort)    Z  zstd compression\n\n--exclude        FILENAME to exclude  --full-time         Show seconds with -tv\n--mode MODE      Adjust permissions   --owner NAME[:UID]  Set file ownership\n--mtime TIME     Override timestamps  --group NAME[:GID]  Set file group\n--sparse         Record sparse files  --selinux           Save/restore labels\n--restrict       All under one dir    --no-recursion      Skip dir contents\n--numeric-owner  Use numeric uid/gid, not user/group names\n--null           Filenames in -T FILE are null-separated, not newline\n--strip-components NUM  Ignore first NUM directory components when extracting\n--xform=SED      Modify filenames via SED expression (ala s/find/replace/g)\n-I PROG          Filter through PROG to compress or PROG -d to decompress\n\nFilename filter types. Create command line args aren't filtered, extract\ndefaults to --anchored, --exclude defaults to --wildcards-match-slash,\nuse no- prefix to disable:\n\n--anchored  Match name not path       --ignore-case       Case insensitive\n--wildcards Expand *?[] like shell    --wildcards-match-slash"

#define HELP_tail "usage: tail [-n|c NUMBER] [-f|F] [-s SECONDS] [FILE...]\n\nCopy last lines from files to stdout. If no files listed, copy from\nstdin. Filename \"-\" is a synonym for stdin.\n\n-n	Output the last NUMBER lines (default 10), +X counts from start\n-c	Output the last NUMBER bytes, +NUMBER counts from start\n-f	Follow FILE(s) by descriptor, waiting for more data to be appended\n-F	Follow FILE(s) by filename, waiting for more data, and retrying\n-s	Used with -F, sleep SECONDS between retries (default 1)"

#define HELP_strings "usage: strings [-fo] [-t oxd] [-n LEN] [FILE...]\n\nDisplay printable strings in a binary file\n\n-f	Show filename\n-n	At least LEN characters form a string (default 4)\n-o	Show offset (ala -t d)\n-t	Show offset type (o=octal, d=decimal, x=hexadecimal)"

#define HELP_split "usage: split [-a SUFFIX_LEN] [-b BYTES] [-l LINES] [-n PARTS] [INPUT [OUTPUT]]\n\nCopy INPUT (or stdin) data to a series of OUTPUT (or \"x\") files with\nalphabetically increasing suffix (aa, ab, ac... az, ba, bb...).\n\n-a	Suffix length (default 2)\n-b	BYTES/file (10, 10k, 10m, 10g...)\n-l	LINES/file (default 1000)\n-n	PARTS many equal length files"

#define HELP_sort "usage: sort [-CMVbcdfginrsuxz] [FILE...] [-k#[,#[x]] [-t X]] [-o FILE]\n\nSort all lines of text from input files (or stdin) to stdout.\n-g	General numeric sort (double precision with nan and inf)\n-n	Numeric order (instead of alphabetical)\n-r	Reverse\n-u	Unique lines only\n\n-b	Ignore leading blanks (or trailing blanks in second part of key)\n-C	Check whether input is sorted\n-c	Warn if input is unsorted\n-d	Dictionary order (use alphanumeric and whitespace chars only)\n-f	Force uppercase (case insensitive sort)\n-i	Ignore nonprinting characters\n-k	Sort by \"key\" (see below)\n-M	Month sort (jan, feb, etc)\n-o	Output to FILE instead of stdout\n-s	Skip fallback sort (only sort with keys)\n-t	Use a key separator other than whitespace\n-x	Hexadecimal numerical sort\n-V	Version numbers (name-1.234-rc6.5b.tgz)\n-z	Zero (null) terminated lines\n\nSorting by key looks at a subset of the words on each line. -k2 uses the\nsecond word to the end of the line, -k2,2 looks at only the second word,\n-k2,4 looks from the start of the second to the end of the fourth word.\n-k2.4,5 starts from the fourth character of the second word, to the end\nof the fifth word. Negative values count from the end. Specifying multiple\nkeys uses the later keys as tie breakers, in order. A type specifier\nappended to a sort key (such as -2,2n) applies only to sorting that key."

#define HELP_sleep "usage: sleep DURATION...\n\nWait before exiting.\n\nDURATION can be a decimal fraction. An optional suffix can be \"m\"\n(minutes), \"h\" (hours), \"d\" (days), or \"s\" (seconds, the default)."

#define HELP_sed "usage: sed [-inrszE] [-e SCRIPT]...|SCRIPT [-f SCRIPT_FILE]... [FILE...]\n\nStream editor. Apply editing SCRIPTs to lines of input.\n\n-e	Add SCRIPT to list\n-f	Add contents of SCRIPT_FILE to list\n-i	Edit each file in place (-iEXT keeps backup file with extension EXT)\n-n	No default output (use the p command to output matched lines)\n-r	Use extended regular expression syntax\n-E	POSIX alias for -r\n-s	Treat input files separately (implied by -i)\n-z	Use \\0 rather than \\n as input line separator\n\nA SCRIPT is one or more COMMANDs separated by newlines or semicolons.\nAll -e SCRIPTs and -f SCRIPT_FILE contents are combined in order as if\nseparated by newlines. If no -e or -f then first argument is the SCRIPT.\n\nCOMMANDs apply to every line unless prefixed with an ADDRESS of the form:\n\n  [ADDRESS[,ADDRESS]][!]COMMAND\n\nADDRESS is a line number (starting at 1), a /REGULAR EXPRESSION/, or $ for\nlast line (-s or -i makes it last line of each file). One address matches one\nline, ADDRESS,ADDRESS matches from first to second inclusive. Two regexes can\nmatch multiple ranges. ADDRESS,+N ends N lines later. ! inverts the match.\n\nREGULAR EXPRESSIONS start and end with the same character (anything but\nbackslash or newline). To use the delimiter in the regex escape it with a\nbackslash, and printf escapes (\\abcefnrtv and octal, hex, and unicode) work.\nAn empty regex repeats the previous one. ADDRESS regexes require any\nfirst delimiter except / to be \\escaped to distinguish it from COMMANDs.\n\nSed reads each line of input, processes it, and writes it out or discards it\nbefore reading the next. Sed can remember one additional line in a separate\nbuffer (the h, H, g, G, and x commands), and can read the next line of input\nearly (the n and N commands), but otherwise operates on individual lines.\n\nEach COMMAND starts with a single character. Commands with no arguments are:\n\n  !  Run this command when the ADDRESS _didn't_ match.\n  {  Start new command block, continuing until a corresponding \"}\".\n     Command blocks nest and can have ADDRESSes applying to the whole block.\n  }  End command block (this COMMAND cannot have an address)\n  d  Delete this line and move on to the next one\n     (ignores remaining COMMANDs)\n  D  Delete one line of input and restart command SCRIPT (same as \"d\"\n     unless you've glued lines together with \"N\" or similar)\n  g  Get remembered line (overwriting current line)\n  G  Get remembered line (appending to current line)\n  h  Remember this line (overwriting remembered line)\n  H  Remember this line (appending to remembered line, if any)\n  l  Print line escaping \\abfrtvn, octal escape other nonprintng chars,\n     wrap lines to terminal width with \\, append $ to end of line.\n  n  Print default output and read next line over current line (quit at EOF)\n  N  Append \\n and next line of input to this line. Quit at EOF without\n     default output. Advances line counter for ADDRESS and \"=\".\n  p  Print this line\n  P  Print this line up to first newline (from \"N\")\n  q  Quit (print default output, no more commands processed or lines read)\n  x  Exchange this line with remembered line (overwrite in both directions)\n  =  Print the current line number (plus newline)\n  #  Comment, ignores rest of this line of SCRIPT (until newline)\n\nCommands that take an argument:\n\n  : LABEL    Target for jump commands\n  a TEXT     Append text to output before reading next line\n  b LABEL    Branch, jumps to :LABEL (with no LABEL to end of SCRIPT)\n  c TEXT     Delete matching ADDRESS range and output TEXT instead\n  i TEXT     Insert text (output immediately)\n  r FILE     Append contents of FILE to output before reading next line.\n  s/S/R/F    Search for regex S replace match with R using flags F. Delimiter\n             is anything but \\n or \\, escape with \\ to use in S or R. Printf\n             escapes work. Unescaped & in R becomes full matched text, \\1\n             through \\9 = parenthetical subexpression from S. \\ at end of\n             line appends next line of SCRIPT. The flags in F are:\n             [0-9]    A number N, substitute only Nth match\n             g        Global, substitute all matches\n             i/I      Ignore case when matching\n             p        Print resulting line when match found and replaced\n             w [file] Write (append) line to file when match replaced\n  t LABEL    Test, jump if s/// command matched this line since last test\n  T LABEL    Test false, jump to :LABEL only if no s/// found a match\n  w FILE     Write (append) line to file\n  y/old/new/ Change each character in 'old' to corresponding character\n             in 'new' (with standard backslash escapes, delimiter can be\n             any repeated character except \\ or \\n)\n\nThe TEXT arguments (to a c i) may end with an unescaped \"\\\" to append\nthe next line (leading whitespace is not skipped), and treat \";\" as a\nliteral character (use \"\\;\" instead)."

#define HELP_rmdir "usage: rmdir [-p] [DIR...]\n\nRemove one or more directories.\n\n-p	Remove path\n--ignore-fail-on-non-empty	Ignore failures caused by non-empty directories"

#define HELP_rm "usage: rm [-fiRrv] FILE...\n\nRemove each argument from the filesystem.\n\n-f	Force: remove without confirmation, no error if it doesn't exist\n-i	Interactive: prompt for confirmation\n-rR	Recursive: remove directory contents\n-v	Verbose"

#define HELP_renice "usage: renice [-gpu] -n INCREMENT ID...\n\n-g	Group ids\n-p	Process ids (default)\n-u	User ids"

#define HELP_pwd "usage: pwd [-L|-P]\n\nPrint working (current) directory.\n\n-L	Use shell's path from $PWD (when applicable)\n-P	Print canonical absolute path"

#define HELP_pkill "usage: pkill [-fnovx] [-SIGNAL|-l SIGNAL] [PATTERN] [-G GID,] [-g PGRP,] [-P PPID,] [-s SID,] [-t TERM,] [-U UID,] [-u EUID,]\n\n-l	Send SIGNAL (default SIGTERM)\n-V	Verbose\n-f	Check full command line for PATTERN\n-G	Match real Group ID(s)\n-g	Match Process Group(s) (0 is current user)\n-n	Newest match only\n-o	Oldest match only\n-P	Match Parent Process ID(s)\n-s	Match Session ID(s) (0 for current)\n-t	Match Terminal(s)\n-U	Match real User ID(s)\n-u	Match effective User ID(s)\n-v	Negate the match\n-x	Match whole command (not substring)"

#define HELP_pgrep "usage: pgrep [-clfnovx] [-d DELIM] [-L SIGNAL] [PATTERN] [-G GID,] [-g PGRP,] [-P PPID,] [-s SID,] [-t TERM,] [-U UID,] [-u EUID,]\n\nSearch for process(es). PATTERN is an extended regular expression checked\nagainst command names.\n\n-c	Show only count of matches\n-d	Use DELIM instead of newline\n-L	Send SIGNAL instead of printing name\n-l	Show command name\n-f	Check full command line for PATTERN\n-G	Match real Group ID(s)\n-g	Match Process Group(s) (0 is current user)\n-n	Newest match only\n-o	Oldest match only\n-P	Match Parent Process ID(s)\n-s	Match Session ID(s) (0 for current)\n-t	Match Terminal(s)\n-U	Match real User ID(s)\n-u	Match effective User ID(s)\n-v	Negate the match\n-x	Match whole command (not substring)"

#define HELP_iotop "usage: iotop [-AaKObq] [-n NUMBER] [-d SECONDS] [-p PID,] [-u USER,]\n\nRank processes by I/O.\n\n-A	All I/O, not just disk\n-a	Accumulated I/O (not percentage)\n-H	Show threads\n-K	Kilobytes\n-k	Fallback sort FIELDS (default -[D]IO,-ETIME,-PID)\n-m	Maximum number of tasks to show\n-O	Only show processes doing I/O\n-o	Show FIELDS (default PID,PR,USER,[D]READ,[D]WRITE,SWAP,[D]IO,COMM)\n-s	Sort by field number (0-X, default 6)\n-b	Batch mode (no tty)\n-d	Delay SECONDS between each cycle (default 3)\n-n	Exit after NUMBER iterations\n-p	Show these PIDs\n-u	Show these USERs\n-q	Quiet (no header lines)\n\nCursor LEFT/RIGHT to change sort, UP/DOWN move list, space to force\nupdate, R to reverse sort, Q to exit."

#define HELP_top "usage: top [-Hhbq] [-k FIELD,] [-o FIELD,] [-s SORT] [-n NUMBER] [-m LINES] [-d SECONDS] [-p PID,] [-u USER,]\n\nShow process activity in real time.\n\n-H	Show threads\n-h	Usage graphs instead of text\n-k	Fallback sort FIELDS (default -S,-%CPU,-ETIME,-PID)\n-o	Show FIELDS (def PID,USER,PR,NI,VIRT,RES,SHR,S,%CPU,%MEM,TIME+,CMDLINE)\n-O	Add FIELDS (replacing PR,NI,VIRT,RES,SHR,S from default)\n-s	Sort by field number (1-X, default 9)\n-b	Batch mode (no tty)\n-d	Delay SECONDS between each cycle (default 3)\n-m	Maximum number of tasks to show\n-n	Exit after NUMBER iterations\n-p	Show these PIDs\n-u	Show these USERs\n-q	Quiet (no header lines)\n\nCursor UP/DOWN or LEFT/RIGHT to move list, SHIFT LEFT/RIGHT to change sort,\nspace to force update, R to reverse sort, Q to exit."

#define HELP_ps "usage: ps [-AadefLlnwZ] [-gG GROUP,] [-k FIELD,] [-o FIELD,] [-p PID,] [-t TTY,] [-uU USER,]\n\nList processes.\n\nWhich processes to show (-gGuUpPt selections may be comma separated lists):\n\n-A  All					-a  Has terminal not session leader\n-d  All but session leaders		-e  Synonym for -A\n-g  In GROUPs				-G  In real GROUPs (before sgid)\n-p  PIDs (--pid)			-P  Parent PIDs (--ppid)\n-s  In session IDs			-t  Attached to selected TTYs\n-T  Show threads also			-u  Owned by selected USERs\n-U  Real USERs (before suid)\n\nOutput modifiers:\n\n-k  Sort FIELDs (-FIELD to reverse)	-M  Measure/pad future field widths\n-n  Show numeric USER and GROUP		-w  Wide output (don't truncate fields)\n\nWhich FIELDs to show. (-o HELP for list, default = -o PID,TTY,TIME,CMD)\n\n-f  Full listing (-o USER:12=UID,PID,PPID,C,STIME,TTY,TIME,ARGS=CMD)\n-l  Long listing (-o F,S,UID,PID,PPID,C,PRI,NI,ADDR,SZ,WCHAN,TTY,TIME,CMD)\n-o  Output FIELDs instead of defaults, each with optional :size and =title\n-O  Add FIELDS to defaults\n-Z  Include LABEL"

#define HELP_printf "usage: printf FORMAT [ARGUMENT...]\n\nFormat and print ARGUMENT(s) according to FORMAT, using C printf syntax\n(% escapes for cdeEfgGiosuxX, \\ escapes for abefnrtv0 or \\OCTAL or \\xHEX)."

#define HELP_patch "usage: patch [-Rlsuv] [-d DIR] [-i FILE] [-p DEPTH] [-F FUZZ] [--dry-run] [FILE [PATCH]]\n\nApply a unified diff to one or more files.\n\n-d	Modify files in DIR\n-F	Fuzz factor (number of non-matching context lines allowed per hunk)\n-i	Input patch from FILE (default=stdin)\n-l	Loose match (ignore whitespace)\n-p	Number of '/' to strip from start of file paths (default=all)\n-R	Reverse patch\n-s	Silent except for errors\n-v	Verbose (-vv to see decisions)\n--dry-run Don't change files, just confirm patch applies\n\nOnly handles \"unified\" diff format (-u is assumed and ignored). Only\nmodifies files when all hunks to that file apply. Prints failed hunks\nto stderr, and exits with nonzero status if any hunks fail.\n\nFiles compared against /dev/null (or with a date <= the unix epoch) are\ncreated/deleted as appropriate. Default -F value is the number of\nleading/trailing context lines minus one (usually 2)."

#define HELP_paste "usage: paste [-s] [-d DELIMITERS] [FILE...]\n\nMerge corresponding lines from each input file.\n\n-d	List of delimiter characters to separate fields with (default is \\t)\n-s	Sequential mode: turn each input file into one line of output"

#define HELP_od "usage: od [-bcdosxv] [-j #] [-N #] [-w #] [-A doxn] [-t acdfoux[#]]\n\nDump data in octal/hex.\n\n-A	Address base (decimal, octal, hexadecimal, none)\n-j	Skip this many bytes of input\n-N	Stop dumping after this many bytes\n-t	Output type a(scii) c(har) d(ecimal) f(loat) o(ctal) u(nsigned) (he)x\n	plus optional size in bytes\n	aliases: -b=-t o1, -c=-t c, -d=-t u2, -o=-t o2, -s=-t d2, -x=-t x2\n-v	Don't collapse repeated lines together\n-w	Total line width in bytes (default 16)"

#define HELP_nohup "usage: nohup COMMAND...\n\nRun a command that survives the end of its terminal.\n\nRedirect tty on stdin to /dev/null, tty on stdout to \"nohup.out\"."

#define HELP_nl "usage: nl [-E] [-l #] [-b MODE] [-n STYLE] [-s SEPARATOR] [-v #] [-w WIDTH] [FILE...]\n\nNumber lines of input.\n\n-E	Use extended regex syntax (when doing -b pREGEX)\n-b	Which lines to number: a (all) t (non-empty, default) pREGEX (pattern)\n-l	Only count last of this many consecutive blank lines\n-n	Number STYLE: ln (left justified) rn (right justified) rz (zero pad)\n-s	Separator to use between number and line (instead of TAB)\n-v	Starting line number for each section (default 1)\n-w	Width of line numbers (default 6)"

#define HELP_nice "usage: nice [-n PRIORITY] COMMAND...\n\nRun a command line at an increased or decreased scheduling priority.\n\nHigher numbers make a program yield more CPU time, from -20 (highest\npriority) to 19 (lowest).  By default processes inherit their parent's\nniceness (usually 0).  By default this command adds 10 to the parent's\npriority.  Only root can set a negative niceness level.\n\n-n	Add given adjustment to priority (default 10)"

#define HELP_mkfifo_z "usage: mkfifo [-Z CONTEXT]\n\n-Z	Security context"

#define HELP_mkfifo "usage: mkfifo [NAME...]\n\nCreate FIFOs (named pipes)."

#define HELP_mkdir_z "usage: [-Z context]\n\n-Z	Set security context"

#define HELP_mkdir "usage: mkdir [-vp] [-m MODE] [DIR...]\n\nCreate one or more directories.\n\n-m	Set permissions of directory to mode\n-p	Make parent directories as needed\n-v	Verbose"

#define HELP_ls "usage: ls [-1ACFHLNRSUXZabcdfghilmnopqrstuwx] [--color[=auto]] [FILE...]\n\nList files\n\nwhat to show:\n-A  all files except . and ..      -a  all files including .hidden\n-b  escape nongraphic chars        -d  directory, not contents\n-F  append /dir *exe @sym |FIFO    -f  files (no sort/filter/format)\n-H  follow command line symlinks   -i  inode number\n-L  follow symlinks                -N  no escaping, even on tty\n-p  put '/' after dir names        -q  unprintable chars as '?'\n-R  recursively list in subdirs    -s  storage used (units of --block-size)\n-Z  security context\n\noutput formats:\n-1  list one file per line         -C  columns (sorted vertically)\n-g  like -l but no owner           -h  human readable sizes\n-k  reset --block-size to default  -l  long (show full details)\n-m  comma separated                -ll long with nanoseconds (--full-time)\n-n  long with numeric uid/gid      -o  long without group column\n-r  reverse order                  -w  set column width\n-x  columns (horizontal sort)\n\nsort by:  (also --sort=longname,longname... ends with alphabetical)\n-c  ctime      -r  reverse    -S  size     -t  time    -u  atime    -U  none\n-X  extension  -!  dirfirst   -~  nocase\n\n--block-size N	block size for -s (default 1024, -k resets to 1024)\n--color  =always (default)  =auto (when stdout is tty) =never\n    exe=green  suid=red  suidfile=redback  stickydir=greenback\n    device=yellow  symlink=turquoise/red  dir=blue  socket=purple\n\nLong output uses -cu for display, use -ltc/-ltu to also sort by ctime/atime."

#define HELP_logger "usage: logger [-s] [-t TAG] [-p [FACILITY.]PRIORITY] [MESSAGE...]\n\nLog message (or stdin) to syslog.\n\n-s	Also write message to stderr\n-t	Use TAG instead of username to identify message source\n-p	Specify PRIORITY with optional FACILITY. Default is \"user.notice\""

#define HELP_ln "usage: ln [-fnrsTv] [-t DIR] [FROM...] TO\n\nCreate a link between FROM and TO.\nOne/two/many arguments work like \"mv\" or \"cp\".\n\n-f	Force the creation of the link, even if TO already exists\n-n	Symlink at TO treated as file\n-r	Create relative symlink from -> to\n-s	Create a symbolic link\n-t	Create links in DIR\n-T	TO always treated as file, max 2 arguments\n-v	Verbose"

#define HELP_link "usage: link FILE NEWLINK\n\nCreate hardlink to a file."

#define HELP_killall5 "usage: killall5 [-l [SIGNAL]] [-SIGNAL|-s SIGNAL] [-o PID]...\n\nSend a signal to all processes outside current session.\n\n-l	List signal name(s) and number(s)\n-o PID	Omit PID\n-s	Send SIGNAL (default SIGTERM)"

#define HELP_kill "usage: kill [-l [SIGNAL] | -s SIGNAL | -SIGNAL] PID...\n\nSend signal to process(es).\n\n-l	List signal name(s) and number(s)\n-s	Send SIGNAL (default SIGTERM)"

#define HELP_whoami "usage: whoami\n\nPrint the current user name."

#define HELP_logname "usage: logname\n\nPrint the current user name."

#define HELP_groups "usage: groups [user]\n\nPrint the groups a user is in."

#define HELP_id_z "usage: id [-Z]\n\n-Z	Show only security context"

#define HELP_id "usage: id [-Ggnru] [USER...]\n\nPrint user and group ID.\n\n-G	Show all group IDs\n-g	Show only the effective group ID\n-n	Print names instead of numeric IDs (to be used with -Ggu)\n-r	Show real ID instead of effective ID\n-u	Show only the effective user ID"

#define HELP_iconv "usage: iconv [-f FROM] [-t TO] [FILE...]\n\nConvert character encoding of files.\n\n-c	Omit invalid chars\n-f	Convert from (default UTF-8)\n-t	Convert to   (default UTF-8)"

#define HELP_head "usage: head [-cn NUM] [-qv] [FILE...]\n\nCopy first lines from files to stdout. If no files listed, copy from\nstdin. Filename \"-\" is a synonym for stdin.\n\n-n	Number of lines to copy\n-c	Number of bytes to copy\n-q	Never print headers\n-v	Always print headers"

#define HELP_grep "usage: grep [-abcEFHhIiLlnoqrsvwxZz] [-ABC NUM] [-m MAX] [-e REGEX]... [-MS PATTERN]... [-f REGFILE]... [FILE]...\n\nShow lines matching regular expressions. If no -e, first argument is\nregular expression to match. With no files (or \"-\" filename) read stdin.\nReturns 0 if matched, 1 if no match found, 2 for command errors.\n\n-e  Regex(es) to match.       -f  File(s) of regexes to match (1 per line).\n\nfile search:\n-r  Recurse into subdirs     -R  Recurse following symlinks\n-M  Match files (--include)  -S  Skip files (--exclude)\n-I  Ignore binary files      --exclude-dir=PATTERN  Skip directories\n\nmatch type:\n-A  Show NUM lines after     -B  Show NUM lines before match\n-C  NUM lines context (A+B)  -E  extended regex syntax\n-F  fixed (literal match)    -a  always text (not binary)\n-i  case insensitive         -m  match MAX many lines\n-v  invert match             -w  whole word (implies -E)\n-x  whole line               -z  input NUL terminated\n\ndisplay modes: (default: matched line)\n-L  filenames with no match  -Z  output is NUL terminated\n-c  count of matching lines  -l  filenames with a match\n-o  only matching part       -q  quiet (errors only)\n-s  silent (no error msg)\n\noutput prefix (default: filename if checking more than 1 file)\n-H  force filename           -b  byte offset of match\n-h  hide filename            -n  line number of match"

#define HELP_getconf "usage: getconf -a [PATH] | -l | NAME [PATH]\n\nGet system configuration values. Values from pathconf(3) require a path.\n\n-a	Show all (defaults to \"/\" if no path given)\n-l	List available value names (grouped by source)"

#define HELP_fold "usage: fold [-bs] [-w WIDTH] [FILE...]\n\nBreak long lines by inserting newlines.\n\n-b	Count bytes instead of utf-8 unicode columns\n-s	Wrap at whitespace when possible\n-w	Break at WIDTH columns (default 80)"

#define HELP_find "usage: find [-HL] [DIR...] [<options>]\n\nSearch directories for matching files.\nDefault: search \".\", match all, -print matches.\n\n-H  Follow command line symlinks         -L  Follow all symlinks\n\nMatch filters:\n-name  PATTERN   filename with wildcards   -iname      ignore case -name\n-path  PATTERN   path name with wildcards  -ipath      ignore case -path\n-user  UNAME     belongs to user UNAME     -nouser     user ID not known\n-group GROUP     belongs to group GROUP    -nogroup    group ID not known\n-perm  [-/]MODE  permissions (-=min /=any) -prune      ignore dir contents\n-size  N[c]      512 byte blocks (c=bytes) -xdev       only this filesystem\n-links N         hardlink count            -empty      empty files and dirs\n-atime N[u]      accessed N units ago      -true       always true\n-ctime N[u]      created N units ago       -false      always false\n-mtime N[u]      modified N units ago      -executable access(X_OK) perm+ACL\n-inum  N         inode number N            -readable   access(R_OK) perm+ACL\n-context PATTERN security context          -depth      contents before dir\n-samefile FILE   hardlink to FILE          -maxdepth N at most N dirs down\n-newer    FILE   newer mtime than FILE     -mindepth N at least N dirs down\n-newerXY  FILE   X=acm time > FILE's Y=acm time (Y=t: FILE is literal time)\n-type [bcdflps]  type is (block, char, dir, file, symlink, pipe, socket)\n\nNumbers N may be prefixed by - (less than) or + (greater than). Units for\n-[acm]time are d (days, default), h (hours), m (minutes), or s (seconds).\n\nCombine matches with:\n!, -a, -o, ( )    not, and, or, group expressions\n\nActions:\n-print  Print match with newline  -print0        Print match with null\n-exec   Run command with path     -execdir       Run command in file's dir\n-ok     Ask before exec           -okdir         Ask before execdir\n-delete Remove matching file/dir  -printf FORMAT Print using format string\n-quit   Exit immediately\n\nCommands substitute \"{}\" with matched file. End with \";\" to run each file,\nor \"+\" (next argument after \"{}\") to collect and run with multiple files.\n\n-printf FORMAT characters are \\ escapes and:\n%b  512 byte blocks used\n%f  basename            %g  textual gid          %G  numeric gid\n%i  decimal inode       %l  target of symlink    %m  octal mode\n%M  ls format type/mode %p  path to file         %P  path to file minus DIR\n%s  size in bytes       %T@ mod time as unixtime\n%u  username            %U  numeric uid          %Z  security context"

#define HELP_file "usage: file [-bhLs] [FILE...]\n\nExamine the given files and describe their content types.\n\n-b	Brief (no filename)\n-h	Don't follow symlinks (default)\n-L	Follow symlinks\n-s	Show block/char device contents"

#define HELP_false "usage: false\n\nReturn nonzero."

#define HELP_expand "usage: expand [-t TABLIST] [FILE...]\n\nExpand tabs to spaces according to tabstops.\n\n-t	TABLIST\n\nSpecify tab stops, either a single number instead of the default 8,\nor a comma separated list of increasing numbers representing tabstop\npositions (absolute, not increments) with each additional tab beyond\nthat becoming one space."

#define HELP_env "usage: env [-0i] [-e FILE] [-u NAME] [NAME=VALUE...] [COMMAND...]\n\nSet the environment for command invocation, or list environment variables.\n\n-e	Execute FILE instead of argv[0] in COMMAND list\n-i	Clear existing environment\n-u NAME	Remove NAME from the environment\n-0	Use null instead of newline in output"

#define HELP_echo "usage: echo [-Een] [ARG...]\n\nWrite each argument to stdout, one space between each, followed by a newline.\n\n-E	Print escape sequences literally (default)\n-e	Process the following escape sequences:\n	\\\\  Backslash		\\0NNN Octal (1-3 digit)	\\xHH Hex (1-2 digit)\n	\\a  Alert (beep/flash)	\\b  Backspace		\\c  Stop here (no \\n)\n	\\f  Form feed		\\n  Newline		\\r  Carriage return\n	\\t  Horizontal tab	\\v  Vertical tab\n-n	No trailing newline"

#define HELP_du "usage: du [-d N] [-abcHKkLlmsx] [FILE...]\n\nShow disk usage, space consumed by files and directories.\n\nSize in:\n-b	Apparent bytes (directory listing size, not space used)\n-h	Human readable (e.g., 1K 243M 2G)\n-k	1024 byte blocks (default)\n-K	512 byte blocks (posix)\n-m	Megabytes\n\nWhat to show:\n-a	All files, not just directories\n-c	Cumulative total\n-d N	Only depth < N\n-H	Follow symlinks on cmdline\n-L	Follow all symlinks\n-l	Disable hardlink filter\n-s	Only total size of each argument\n-x	Don't leave this filesystem"

#define HELP_dirname "usage: dirname PATH...\n\nShow directory portion of path."

#define HELP_df "usage: df [-aHhikP] [-t TYPE] [FILE...]\n\nThe \"disk free\" command shows total/used/available disk space for\neach filesystem listed on the command line, or all currently mounted\nfilesystems.\n\n-a	Show all (including /proc and friends)\n-H	Human readable (k=1000)\n-h	Human readable (K=1024)\n-i	Show inodes instead of blocks\n-k	Sets units back to 1024 bytes (the default without -P)\n-P	The SUSv3 \"Pedantic\" option (512 byte blocks)\n-t TYPE	Display only filesystems of this type\n\nPedantic provides a slightly less useful output format dictated by POSIX,\nand sets the units to 512 bytes instead of the default 1024 bytes."

#define HELP_dd "usage: dd [if|of=FILE] [ibs|obs|bs|count|seek|skip=N] [conv|status|iflag|oflag=FLAG[,FLAG...]]\n\nCopy/convert blocks of data from input to output, with the following\nkeyword=value modifiers (and their default values):\n\nif=FILE  Read FILE (stdin)          of=FILE  Write to FILE (stdout)\n   bs=N  Block size in bytes (512)  count=N  Stop after copying N blocks (all)\n  ibs=N  Input block size (bs=)       obs=N  Output block size (bs=)\n skip=N  Skip N input blocks (0)     seek=N  Skip N output blocks (0)\n\nEach =N value accepts the normal unit suffixes (see toybox --help).\n\nThese modifiers take a comma separated list of potential options:\n\niflag=count_bytes,skip_bytes   count=N or skip=N is in bytes not blocks\noflag=seek_bytes,append        seek=N is in bytes, append output to file\nstatus=noxfer,none             don't show transfer rate, no summary info\nconv=\n  notrunc  Don't truncate output    noerror  Continue after read errors\n  sync     Zero pad short reads     fsync    Flush output to disk at end\n  sparse   Seek past zeroed output  excl     Fail if output file exists\n  nocreat  Fail if of=FILE missing"

#define HELP_date "usage: date [-u] [-I RES] [-r FILE] [-d DATE] [+DISPLAY_FORMAT] [-D SET_FORMAT] [SET]\n\nSet/get the current date/time. With no SET shows the current date.\n\n-d	Show DATE instead of current time (convert date format)\n-D	+FORMAT for SET or -d (instead of MMDDhhmm[[CC]YY][.ss])\n-I RES	ISO 8601 with RESolution d=date/h=hours/m=minutes/s=seconds/n=ns\n-r	Use modification time of FILE instead of current date\n-s DATE	Set the system clock to DATE.\n-u	Use UTC instead of current timezone\n\nSupported input formats:\n\nMMDDhhmm[[CC]YY][.ss]     POSIX\n@UNIXTIME[.FRACTION]      seconds since midnight 1970-01-01\nYYYY-MM-DD [hh:mm[:ss]]   ISO 8601\nhh:mm[:ss]                24-hour time today\n\nAll input formats can be followed by fractional seconds, and/or a UTC\noffset such as -0800.\n\nAll input formats can be preceded by TZ=\"id\" to set the input time zone\nseparately from the output time zone. Otherwise $TZ sets both.\n\n+FORMAT specifies display format string using strftime(3) syntax:\n\n%% literal %             %n newline              %t tab\n%S seconds (00-60)       %M minute (00-59)       %m month (01-12)\n%H hour (0-23)           %I hour (01-12)         %p AM/PM\n%y short year (00-99)    %Y year                 %C century\n%a short weekday name    %A weekday name         %u day of week (1-7, 1=mon)\n%b short month name      %B month name           %Z timezone name\n%j day of year (001-366) %d day of month (01-31) %e day of month ( 1-31)\n%N nanosec (output only)\n\n%U Week of year (0-53 start Sunday)   %W Week of year (0-53 start Monday)\n%V Week of year (1-53 start Monday, week < 4 days not part of this year)\n\n%F \"%Y-%m-%d\"   %R \"%H:%M\"        %T \"%H:%M:%S\"        %z  timezone (-0800)\n%D \"%m/%d/%y\"   %r \"%I:%M:%S %p\"  %h \"%b\"              %:z timezone (-08:00)\n%x locale date  %X locale time    %c locale date/time  %s  unix epoch time"

#define HELP_cut "usage: cut [-Ds] [-bcCfF LIST] [-dO DELIM] [FILE...]\n\nPrint selected parts of lines from each FILE to standard output.\n\nEach selection LIST is comma separated, either numbers (counting from 1)\nor dash separated ranges (inclusive, with X- meaning to end of line and -X\nfrom start). By default selection ranges are sorted and collated, use -D\nto prevent that.\n\n-b	Select bytes (with -n round start/end down to start of utf8 char)\n-c	Select UTF-8 characters\n-C	Select unicode columns\n-d	Input delimiter (default is TAB for -f, run of whitespace for -F)\n-D	Don't sort/collate selections or match -fF lines without delimiter\n-f	Select fields (words) separated by single DELIM character\n-F	Select fields separated by DELIM regex\n-O	Output separator (default one space for -F, input delim for -f)\n-s	Skip lines without delimiters"

#define HELP_cpio "usage: cpio -{o|t|i|p DEST} [-dLtuv] [--verbose] [-F FILE] [-R [USER][:GROUP] [--no-preserve-owner]\n\nCopy files into and out of a \"newc\" format cpio archive.\n\n-d	Create directories if needed\n-F FILE	Use archive FILE instead of stdin/stdout\n-i	Extract from archive into file system (stdin=archive)\n-L	Follow symlinks\n-o	Create archive (stdin=list of files, stdout=archive)\n-p DEST	Copy-pass mode, copy stdin file list to directory DEST\n-R USER	Replace owner with USER[:GROUP]\n-t	Test files (list only, stdin=archive, stdout=list of files)\n-u	Unlink existing files when extracting\n-v	Verbose\n--no-preserve-owner     Don't set ownership during extract"

#define HELP_install "usage: install [-dDpsv] [-o USER] [-g GROUP] [-m MODE] [-t TARGET] [SOURCE...] [DEST]\n\nCopy files and set attributes.\n\n-d	Act like mkdir -p\n-D	Create leading directories for DEST\n-g	Make copy belong to GROUP\n-m	Set permissions to MODE\n-o	Make copy belong to USER\n-p	Preserve timestamps\n-s	Call \"strip -p\"\n-t	Copy files to TARGET dir (no DEST)\n-v	Verbose"

#define HELP_mv "usage: mv [-FfinTvx] [-t TARGET] SOURCE... [DEST]\n\n-F	Delete any existing DEST first (--remove-destination)\n-f	Force copy by deleting destination file\n-i	Interactive, prompt before overwriting existing DEST\n-n	No clobber (don't overwrite DEST)\n-t	Move to TARGET dir (no DEST)\n-T	DEST always treated as file, max 2 arguments\n-v	Verbose\n-x	Atomically exchange source/dest (--swap)"

#define HELP_cp "usage: cp [-aDdFfHiLlnPpRrsTuv] [--preserve=motcxa] [-t TARGET] SOURCE... [DEST]\n\nCopy files from SOURCE to DEST.  If more than one SOURCE, DEST must\nbe a directory.\n\n-a	Same as -dpr\n-D	Create leading dirs under DEST (--parents)\n-d	Don't dereference symlinks\n-F	Delete any existing DEST first (--remove-destination)\n-f	Delete destination files we can't write to\n-H	Follow symlinks listed on command line\n-i	Interactive, prompt before overwriting existing DEST\n-L	Follow all symlinks\n-l	Hard link instead of copy\n-n	No clobber (don't overwrite DEST)\n-P	Do not follow symlinks\n-p	Preserve timestamps, ownership, and mode\n-R	Recurse into subdirectories (DEST must be a directory)\n-r	Synonym for -R\n-s	Symlink instead of copy\n-T	DEST always treated as file, max 2 arguments\n-t	Copy to TARGET dir (no DEST)\n-u	Update (keep newest mtime)\n-v	Verbose\n\nArguments to --preserve are the first letter(s) of:\n\n        mode - permissions (ignore umask for rwx, copy suid and sticky bit)\n   ownership - user and group\n  timestamps - file creation, modification, and access times.\n     context - security context\n       xattr - extended attributes\n         all - all of the above"

#define HELP_comm "usage: comm [-123] FILE1 FILE2\n\nRead FILE1 and FILE2, which should be ordered, and produce three text\ncolumns as output: lines only in FILE1; lines only in FILE2; and lines\nin both files. Filename \"-\" is a synonym for stdin.\n\n-1	Suppress the output column of lines unique to FILE1\n-2	Suppress the output column of lines unique to FILE2\n-3	Suppress the output column of lines duplicated in FILE1 and FILE2"

#define HELP_cmp "usage: cmp [-ls] [-n LEN] FILE1 [FILE2 [SKIP1 [SKIP2]]]\n\nCompare the contents of files (vs stdin if only one given), optionally\nskipping bytes at start.\n\n-l	Show all differing bytes\n-n LEN	Compare at most LEN bytes\n-s	Silent"

#define HELP_crc32 "usage: crc32 [file...]\n\nOutput crc32 checksum for each file."

#define HELP_cksum "usage: cksum [-HIPLN] [FILE...]\n\nFor each file, output crc32 checksum value, length and name of file.\nIf no files listed, copy from stdin.  Filename \"-\" is a synonym for stdin.\n\n-H	Hexadecimal checksum (defaults to decimal)\n-I	Skip post-inversion\n-P	Pre-inversion\n-L	Little endian (defaults to big endian)\n-N	Do not include length in CRC calculation (or output)"

#define HELP_chmod "usage: chmod [-R] MODE FILE...\n\nChange mode of listed file[s] (recursively with -R).\n\nMODE can be (comma-separated) stanzas: [ugoa][+-=][rwxstXugo]\n\nStanzas are applied in order: For each category (u = user,\ng = group, o = other, a = all three, if none specified default is a),\nset (+), clear (-), or copy (=), r = read, w = write, x = execute.\ns = u+s = suid, g+s = sgid, +t = sticky. (o+s ignored so a+s doesn't set +t)\nsuid/sgid: execute as the user/group who owns the file.\nsticky: can't delete files you don't own out of this directory\nX = x for directories or if any category already has x set.\n\nOr MODE can be an octal value up to 7777	ug uuugggooo	top +\nbit 1 = o+x, bit 1<<8 = u+w, 1<<11 = g+1	sstrwxrwxrwx	bottom\n\nExamples:\nchmod u+w file - allow owner of \"file\" to write to it.\nchmod 744 file - user can read/write/execute, everyone else read only"

#define HELP_chown "see: chgrp"

#define HELP_chgrp "usage: chgrp/chown [-RHLP] [-fvh] GROUP FILE...\n\nChange group of one or more files.\n\n-f	Suppress most error messages\n-h	Change symlinks instead of what they point to\n-R	Recurse into subdirectories (implies -h)\n-H	With -R change target of symlink, follow command line symlinks\n-L	With -R change target of symlink, follow all symlinks\n-P	With -R change symlink, do not follow symlinks (default)\n-v	Verbose"

#define HELP_cat "usage: cat [-etuv] [FILE...]\n\nCopy (concatenate) files to stdout.  If no files listed, copy from stdin.\nFilename \"-\" is a synonym for stdin.\n\n-e	Mark each newline with $\n-t	Show tabs as ^I\n-u	Copy one byte at a time (slow)\n-v	Display nonprinting characters as escape sequences with M-x for\n	high ascii characters (>127), and ^x for other nonprinting chars"

#define HELP_cal "usage: cal [-h] [[[DAY] MONTH] YEAR]\n\nPrint a calendar.\n\nWith one argument, prints all months of the specified year.\nWith two arguments, prints calendar for month and year.\nWith three arguments, highlights day within month and year.\n\n-h	Don't highlight today"

#define HELP_basename "usage: basename [-a] [-s SUFFIX] NAME... | NAME [SUFFIX]\n\nReturn non-directory portion of a pathname removing suffix.\n\n-a		All arguments are names\n-s SUFFIX	Remove suffix (implies -a)"

