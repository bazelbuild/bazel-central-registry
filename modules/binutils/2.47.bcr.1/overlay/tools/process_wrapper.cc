/* process_wrapper: run a program under an adjusted environment, with no shell
   in between.

     process_wrapper [--cwd DIR] [--path DIR]... [--stdin FILE] [--stdout FILE]
                     -- PROGRAM [ARG...]

   --cwd DIR      Create DIR if needed and run PROGRAM in it.  Relative to the
                  directory process_wrapper starts in; `..` is resolved
                  lexically, so an output directory can be named through one
                  of the files Bazel declares in it.
   --path DIR     Prepend DIR, made absolute, to PATH.  PATH falls back to
                  /usr/bin:/bin when unset, as it is inside a Bazel action.
   --stdin FILE   Feed FILE to PROGRAM's standard input.
   --stdout FILE  Send PROGRAM's standard output to FILE.
                  Both are relative to the starting directory.
   `${pwd}` in PROGRAM or any ARG is replaced by the absolute starting
   directory, so PROGRAM can be handed paths that survive --cwd.

   Exits with PROGRAM's status, or 127 when it cannot be started.  */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <string>
#include <vector>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#include <process.h>
#include <sys/stat.h>
#define PATH_SEPARATOR ';'
static int set_path (const std::string &v) { return _putenv_s ("PATH", v.c_str ()); }
static int redirect (int fd, const char *file, bool output)
{
  int f = _open (file, output ? _O_WRONLY | _O_CREAT | _O_TRUNC : _O_RDONLY, _S_IREAD | _S_IWRITE);
  return f < 0 || _dup2 (f, fd) < 0 ? -1 : _close (f);
}
#else
#include <fcntl.h>
#include <unistd.h>
#define PATH_SEPARATOR ':'
static int set_path (const std::string &v) { return setenv ("PATH", v.c_str (), 1); }
static int redirect (int fd, const char *file, bool output)
{
  int f = open (file, output ? O_WRONLY | O_CREAT | O_TRUNC : O_RDONLY, 0666);
  return f < 0 || dup2 (f, fd) < 0 ? -1 : close (f);
}
#endif

namespace fs = std::filesystem;

/* ROOT/P unless P is absolute, with `.` and `..` resolved, in generic (/) form.  */
static std::string
resolve (const fs::path &root, const std::string &p)
{
  return (root / p).lexically_normal ().generic_string ();
}

static void
replace_all (std::string &s, const std::string &from, const std::string &to)
{
  for (size_t at = s.find (from); at != std::string::npos; at = s.find (from, at + to.size ()))
    s.replace (at, from.size (), to);
}

#ifdef _WIN32
/* ARG as one token of a Windows command line: quoted when empty or when it
   contains a space, tab or quote, with `"` escaped as `\"` and the
   backslashes before a quote (or the end) doubled, which is what the
   receiving CRT undoes.  */
static std::string
quote_windows_argument (const std::string &arg)
{
  if (!arg.empty () && arg.find_first_of (" \t\"") == std::string::npos)
    return arg;
  std::string out = "\"";
  size_t backslashes = 0;
  for (size_t i = 0; i < arg.size (); i++)
    {
      if (arg[i] == '\\')
	{
	  backslashes++;
	  continue;
	}
      if (arg[i] == '"')
	out.append (2 * backslashes + 1, '\\');
      else
	out.append (backslashes, '\\');
      backslashes = 0;
      out += arg[i];
    }
  out.append (2 * backslashes, '\\');
  return out + "\"";
}
#endif

static int
usage ()
{
  fputs ("usage: process_wrapper [--cwd DIR] [--path DIR]... [--stdin FILE] [--stdout FILE] -- PROGRAM [ARG...]\n", stderr);
  return 2;
}

int
main (int argc, char **argv)
{
  std::error_code ec;
  fs::path root = fs::current_path (ec);
  if (ec)
    {
      fputs ("process_wrapper: cannot read the current directory\n", stderr);
      return 1;
    }

  std::string cwd, stdin_file, stdout_file, path;
  int i = 1;
  for (; i < argc; i++)
    {
      std::string option = argv[i];
      if (option == "--")
	{
	  i++;
	  break;
	}
      if (i + 1 >= argc)
	return usage ();
      std::string value = argv[++i];
      if (option == "--cwd")
	cwd = value;
      else if (option == "--path")
	path += resolve (root, value) + PATH_SEPARATOR;
      else if (option == "--stdin")
	stdin_file = resolve (root, value);
      else if (option == "--stdout")
	stdout_file = resolve (root, value);
      else
	return usage ();
    }
  if (i >= argc)
    return usage ();

  const char *inherited = getenv ("PATH");
  path += inherited ? inherited : "/usr/bin:/bin";
  if (set_path (path) != 0)
    {
      perror ("process_wrapper: PATH");
      return 1;
    }
  if (!cwd.empty ())
    {
      fs::path dir = resolve (root, cwd);
      fs::create_directories (dir, ec);
      if (!ec)
	fs::current_path (dir, ec);
      if (ec)
	{
	  fprintf (stderr, "process_wrapper: %s: %s\n", dir.generic_string ().c_str (), ec.message ().c_str ());
	  return 1;
	}
    }
  if (!stdin_file.empty () && redirect (0, stdin_file.c_str (), false) != 0)
    {
      perror (("process_wrapper: " + stdin_file).c_str ());
      return 1;
    }
  if (!stdout_file.empty () && redirect (1, stdout_file.c_str (), true) != 0)
    {
      perror (("process_wrapper: " + stdout_file).c_str ());
      return 1;
    }

  std::vector<std::string> args;
  for (; i < argc; i++)
    {
      args.push_back (argv[i]);
      replace_all (args.back (), "${pwd}", root.generic_string ());
    }

#ifdef _WIN32
  /* The CRT's spawn functions join the arguments with spaces and no quoting,
     so quote each one the way the receiving CRT parses a command line.  */
  std::vector<std::string> quoted;
  for (size_t j = 0; j < args.size (); j++)
    quoted.push_back (quote_windows_argument (args[j]));
  std::vector<const char *> argv_out;
  for (size_t j = 0; j < quoted.size (); j++)
    argv_out.push_back (quoted[j].c_str ());
  argv_out.push_back (NULL);
  intptr_t status = _spawnvp (_P_WAIT, args[0].c_str (), argv_out.data ());
  if (status < 0)
    {
      perror (args[0].c_str ());
      return 127;
    }
  return (int) status;
#else
  std::vector<char *> argv_out;
  for (size_t j = 0; j < args.size (); j++)
    argv_out.push_back (&args[j][0]);
  argv_out.push_back (NULL);
  execvp (argv_out[0], argv_out.data ());
  perror (argv_out[0]);
  return 127;
#endif
}
