// Smoke test for the host utilities this module builds.
//
// Four of them are driven the way a user would and their output compared
// with what the reference `./configure && make` build prints: grub-mkimage
// reports the version, a grub-editenv environment block survives a
// create/set/list round trip, grub-script-check accepts a well-formed script
// and rejects a truncated one, and grub-menulst2cfg translates a GRUB Legacy
// menu.lst.  None of these needs a disk, a kernel or root.

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>

#include "rules_cc/cc/runfiles/runfiles.h"

namespace fs = std::filesystem;
using rules_cc::cc::runfiles::Runfiles;

namespace {

int fail(const std::string& message) {
  std::cerr << "smoke_test: " << message << "\n";
  return 1;
}

void write_file(const fs::path& path, const std::string& content) {
  std::ofstream out(path, std::ios::binary);
  out << content;
}

std::string read_file(const fs::path& path) {
  std::ifstream in(path, std::ios::binary);
  std::ostringstream buffer;
  buffer << in.rdbuf();
  return buffer.str();
}

std::string quote(const fs::path& path) { return "\"" + path.string() + "\""; }

int run(const std::string& command) { return std::system(command.c_str()); }

bool ends_with(const std::string& text, const std::string& suffix) {
  return text.size() >= suffix.size() &&
         text.compare(text.size() - suffix.size(), suffix.size(), suffix) == 0;
}

// menulst2cfg's output for MENU_LST, as the reference build prints it.
const char MENU_LST[] =
    "default 0\n"
    "timeout 5\n"
    "\n"
    "title Test\n"
    "root (hd0,0)\n"
    "kernel /vmlinuz ro quiet\n"
    "initrd /initrd.img\n";

const char MENU_CFG[] =
    "set default='0'; if [ x\"$default\" = xsaved ]; then load_env; "
    "set default=\"$saved_entry\"; fi\n"
    "set timeout=5\n"
    "\n"
    "menuentry 'Test' {\n"
    "  set root='(hd0,1)'; set legacy_hdbias='0'\n"
    "  legacy_kernel   '/vmlinuz' '/vmlinuz' 'ro' 'quiet'\n"
    "  legacy_initrd '/initrd.img' '/initrd.img'\n"
    "}\n"
    "\n";

int run_test(char** argv) {
  std::string error;
  // The arguments are $(rlocationpath)s, whose repository names are already
  // canonical, so no repository mapping is needed (and Bazel 7.4's C++ rules
  // do not define BAZEL_CURRENT_REPOSITORY).
  const std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  if (runfiles == nullptr) return fail("could not locate runfiles: " + error);

  fs::path programs[4];
  for (int i = 0; i < 4; ++i) {
    programs[i] = runfiles->Rlocation(argv[i + 1]);
    if (programs[i].empty()) {
      return fail(std::string("not in the runfiles: ") + argv[i + 1]);
    }
  }
  const fs::path& mkimage = programs[0];
  const fs::path& editenv = programs[1];
  const fs::path& script_check = programs[2];
  const fs::path& menulst2cfg = programs[3];

  const char* test_tmpdir = std::getenv("TEST_TMPDIR");
  if (test_tmpdir == nullptr) return fail("TEST_TMPDIR is not set");
  const fs::path work = fs::path(test_tmpdir) / "smoke";
  fs::remove_all(work);
  fs::create_directories(work);

  // grub-mkimage --version.  argp prints the program as it was invoked, so
  // only the tail is fixed.
  const fs::path version = work / "version.txt";
  if (run(quote(mkimage) + " --version > " + quote(version)) != 0) {
    return fail("grub-mkimage --version exited nonzero");
  }
  const std::string version_text = read_file(version);
  if (!ends_with(version_text, " (GRUB) 2.06\n")) {
    return fail("--version output changed:\n" + version_text);
  }

  // grub-editenv create / set / list.
  const fs::path env = work / "grubenv";
  if (run(quote(editenv) + " " + quote(env) + " create") != 0) {
    return fail("grub-editenv create exited nonzero");
  }
  if (run(quote(editenv) + " " + quote(env) + " set a=1 b=two") != 0) {
    return fail("grub-editenv set exited nonzero");
  }
  const fs::path listing = work / "listing.txt";
  if (run(quote(editenv) + " " + quote(env) + " list > " + quote(listing)) !=
      0) {
    return fail("grub-editenv list exited nonzero");
  }
  if (read_file(listing) != "a=1\nb=two\n") {
    return fail("environment block did not round trip:\n" +
                read_file(listing));
  }

  // grub-script-check.
  const fs::path good = work / "good.cfg";
  write_file(good, "menuentry \"x\" {\n  linux /vmlinuz\n}\n");
  if (run(quote(script_check) + " " + quote(good)) != 0) {
    return fail("grub-script-check rejected a well-formed script");
  }
  const fs::path bad = work / "bad.cfg";
  write_file(bad, "menuentry \"x\" {\n");
  if (run(quote(script_check) + " " + quote(bad) + " 2>/dev/null") == 0) {
    return fail("grub-script-check accepted a truncated script");
  }

  // grub-menulst2cfg.
  const fs::path menu_lst = work / "menu.lst";
  write_file(menu_lst, MENU_LST);
  const fs::path menu_cfg = work / "grub.cfg";
  if (run(quote(menulst2cfg) + " " + quote(menu_lst) + " " + quote(menu_cfg)) !=
      0) {
    return fail("grub-menulst2cfg exited nonzero");
  }
  if (read_file(menu_cfg) != MENU_CFG) {
    return fail("menu.lst translation changed:\n" + read_file(menu_cfg));
  }

  return 0;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 5) {
    return fail(
        "usage: smoke_test <rlocationpath of grub-mkimage> <grub-editenv> "
        "<grub-script-check> <grub-menulst2cfg>");
  }
  return run_test(argv);
}
