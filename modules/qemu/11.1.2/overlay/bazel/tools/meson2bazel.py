#!/usr/bin/env python3
"""First-pass translation of a QEMU meson.build into a BUILD.bazel.

Handles the common shape of QEMU's per-directory meson.build files:

    xxx_ss.add(files('a.c', ...), dep, ...)
    xxx_ss.add(when: COND, if_true: files(...), if_false: files(...))
    if CONDITION ... elif ... else ... endif      (simple conditions)
    hw_arch += {'i386': i386_ss}                  (per-target source sets)

and writes one qemu_source_set / qemu_target_source_set per source set.
Anything it does not understand is kept as a `# TODO(meson):` comment for
the person finishing the file by hand.  The output is a starting point,
not something to re-run over a file that has been edited.

usage: meson2bazel.py <dir>            (prints the BUILD file)
"""

import glob
import os
import re
import sys

# Source sets that are compiled per target (meson.build applies them with
# config_target): the target dictionaries they are stored in.
PER_TARGET_DICTS = ("hw_arch", "target_arch", "target_system_arch")
COMMON_ARCH_DICTS = ("hw_common_arch", "target_common_arch", "target_common_system_arch")

# meson variable -> condition key
DEP_KEYS = {
    "linux_io_uring": "linux_io_uring",
}

SYSTEM_SETS = {"system_ss"}

# dependency objects -> labels; genh is implicit (//include:qemu)
DEP_LABELS = {"zlib": "@zlib", "glib": "@glib//glib", "genh": None, "util": "-lutil"}

# dependencies this configuration does not find (meson: not_found); an
# add() of them contributes nothing
NOT_FOUND = {
    "numa", "inotify", "vhost_user", "winmm", "pathcch", "synchronization",
    "freebsd_dep", "zstd", "gnutls", "gcrypt", "nettle", "hogweed", "gmp",
    "coref", "iokit", "libaio", "linux_io_uring", "keyutils", "selinux",
    "pixman", "opengl", "sdl", "gtk", "spice", "libusb", "usbredir",
    "virgl", "rutabaga", "capstone", "libpmem", "libdaxctl", "rdma",
    "libbpf", "libxdp", "u2f", "fdt", "lzo", "snappy", "png", "jpeg",
    "sasl", "curses", "iconv", "libcbor", "libudev", "libdw", "igvm",
    "valgrind", "lttng", "libcap_ng", "seccomp", "xen", "hvf", "qpl",
    "uadk", "qatzip", "brlapi", "vte", "x11", "xkbcommon", "gio",
}


def strip_comments(text):
    out = []
    for line in text.splitlines():
        # a '#' outside a string starts a comment
        q = None
        for i, ch in enumerate(line):
            if q:
                if ch == q:
                    q = None
            elif ch in "'\"":
                q = ch
            elif ch == "#":
                line = line[:i]
                break
        out.append(line.rstrip())
    return "\n".join(out)


def statements(text):
    """Split into logical statements (balanced parentheses/brackets)."""
    buf, depth = "", 0
    for line in text.replace("\\\n", " ").splitlines():
        if not line.strip() and depth == 0:
            continue
        buf += (" " if buf else "") + line.strip()
        depth += line.count("(") + line.count("[") + line.count("{")
        depth -= line.count(")") + line.count("]") + line.count("}")
        if depth <= 0:
            yield buf
            buf, depth = "", 0
    if buf:
        yield buf


def cond_key(expr):
    """A meson condition -> a when() key string, or None."""
    e = expr.strip()
    if e.startswith("(") and e.endswith(")"):
        e = e[1:-1].strip()
    if " or " in e:
        parts = [cond_key(p) for p in re.split(r"\s+or\s+", e)]
        return None if None in parts else "|".join(parts)
    if e.startswith("not "):
        k = cond_key(e[4:])
        return None if k is None or "|" in k else "!" + k
    m = re.fullmatch(r"host_os\s*(==|!=)\s*'(\w+)'", e)
    if m:
        os_key = {"linux": "CONFIG_LINUX", "windows": "CONFIG_WIN32",
                  "darwin": "CONFIG_DARWIN", "freebsd": "CONFIG_FREEBSD",
                  "sunos": "CONFIG_SOLARIS",
                  "emscripten": "host_emscripten"}.get(m.group(2))
        if os_key is None:
            return None
        return os_key if m.group(1) == "==" else "!" + os_key
    if re.fullmatch(r"host_os\s+in\s+bsd_oses", e):
        return "CONFIG_BSD"
    m = re.fullmatch(r"host_os\s+in\s+\[(.*)\]", e)
    if m:
        keys = [cond_key(f"host_os == {x.strip()}") for x in m.group(1).split(",")]
        return None if None in keys else "|".join(keys)
    m = re.fullmatch(r"config_all_devices\.has_key\('(\w+)'\)", e)
    if m:
        return m.group(1)
    m = re.fullmatch(r"config_host_data\.get\('(\w+)'\)", e)
    if m:
        return m.group(1)
    m = re.fullmatch(r"get_option\('(\w+)'\)\.allowed\(\)", e)
    if m:
        return m.group(1)
    m = re.fullmatch(r"get_option\('(\w+)'\)", e)
    if m:
        return m.group(1)
    m = re.fullmatch(r"(\w+)\.found\(\)", e)
    if m:
        return DEP_KEYS.get(m.group(1), m.group(1))
    m = re.fullmatch(r"cpu\s*==\s*'(\w+)'", e)
    if m:
        return "host_cpu=" + m.group(1)
    m = re.fullmatch(r"'(\w+)'", e)
    if m:
        return m.group(1)
    if re.fullmatch(r"have_\w+|glib_has_gslice|dbus_display", e):
        return e
    if re.fullmatch(r"[a-z_0-9]+", e):
        return DEP_KEYS.get(e, e)
    return None


def files_of(expr):
    m = re.search(r"files\((.*?)\)", expr)
    if not m:
        return None
    return re.findall(r"'([^']+)'", m.group(1))


def split_args(s):
    out, buf, depth, q = [], "", 0, None
    for ch in s:
        if q:
            buf += ch
            if ch == q:
                q = None
            continue
        if ch in "'\"":
            q = ch
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(buf.strip())
            buf = ""
        else:
            buf += ch
    if buf.strip():
        out.append(buf.strip())
    return out


class SourceSet:
    def __init__(self, var):
        self.var = var
        self.srcs = []
        self.when = []      # (cond list, if_true, if_false)
        self.deps = set()
        self.todo = []
        self.arch = None
        self.common_arch = False

    def add_when(self, keys, if_true, if_false):
        # consecutive additions under one condition read as one entry
        if self.when and self.when[-1][0] == keys and not if_false and not self.when[-1][2]:
            self.when[-1][1].extend(if_true)
        elif if_true or if_false:
            self.when.append((keys, list(if_true), list(if_false)))


def translate(path):
    text = strip_comments(open(path).read())
    sets = {}
    stack = []      # current if-conditions (keys); None = untranslatable
    todo_top = []
    merges = []     # (into, from, conditions): X.add_all(when: C, if_true: Y)
    subdirs = []
    d = os.path.dirname(path)
    parts = d.split("/")
    arch = parts[1] if len(parts) > 1 and parts[0] in ("target", "hw") else None

    def ss(var):
        return sets.setdefault(var, SourceSet(var))

    def negate(k):
        if k is None:
            return None
        if "|" in k:
            return [negate(x)[0] for x in k.split("|")]
        return [k[1:] if k.startswith("!") else "!" + k]

    # one entry per open if: [conditions of earlier branches negated,
    # conditions of the current branch]; None = not translatable
    levels = []
    for st in statements(text):
        m = re.match(r"(if|elif)\s+(.*)$", st)
        if m:
            k = cond_key(m.group(2))
            if k is None:
                todo_top.append(f"{m.group(1)} {m.group(2)}")
            if m.group(1) == "if":
                levels.append([[], [k]])
            else:
                prior, cur = levels[-1]
                n = negate(cur[-1]) if None not in cur else None
                prior = prior + n if n is not None and None not in n else prior + [None]
                levels[-1] = [prior, prior + [k]]
            stack[:] = [c for _, cur in levels for c in cur]
            continue
        if st == "else":
            prior, cur = levels[-1]
            n = negate(cur[-1]) if None not in cur else None
            levels[-1] = [prior, prior + (n if n is not None and None not in n else [None])]
            stack[:] = [c for _, cur in levels for c in cur]
            continue
        if st == "endif":
            levels.pop()
            stack[:] = [c for _, cur in levels for c in cur]
            continue
        m = re.match(r"(\w+)\s*\+=\s*\{\s*'(\w+)'\s*:\s*(\w+)\s*\}$", st)
        if m and m.group(1) in PER_TARGET_DICTS + COMMON_ARCH_DICTS:
            ss(m.group(3)).arch = m.group(2)
            ss(m.group(3)).common_arch = m.group(1) in COMMON_ARCH_DICTS
            continue
        m = re.match(r"subdir\('([\w/.-]+)'\)$", st)
        if m:
            if None not in stack and all(_static_true(k) for k in stack):
                subdirs.append(m.group(1))
            else:
                todo_top.append(f"subdir('{m.group(1)}') under {stack}")
            continue
        # modules are linked in when --disable-modules (meson.build)
        m = re.match(r"(\w+)_modules\s*\+=\s*\{\s*'[\w-]+'\s*:\s*(\w+)\s*\}$", st)
        if m:
            into = "specific_ss" if m.group(1) == "target" else (
                "block_ss" if d == "block" else "audio_ss" if d == "audio" else "system_ss")
            merges.append((into, m.group(2), list(stack)))
            continue
        if re.match(r"(\w+)\s*=\s*(ss\.source_set\(\)|\{\}|\w+\.apply\(\{\}\))$", st):
            continue
        m = re.match(r"modules\s*\+=\s*\{\s*'[\w-]+'\s*:\s*(.*)\}$", st)
        if m:
            # modules += {'hw-uefi': {'vars': uefi_vars_ss}}: linked in
            # when --disable-modules
            for var in re.findall(r"'[\w-]+'\s*:\s*(\w+_ss)", m.group(1)):
                merges.append(("system_ss", var, list(stack)))
            continue
        m = re.match(r"(\w+_ss)\.add_all\((.*)\)$", st)
        if m:
            args = split_args(m.group(2))
            kw = dict(re.match(r"(\w+)\s*:\s*(.*)$", a).groups() for a in args if re.match(r"\w+\s*:", a))
            pos = [a for a in args if not re.match(r"\w+\s*:", a)]
            src = kw.get("if_true") or (pos[0] if pos else None)
            conds = list(stack)
            if "when" in kw:
                w = kw["when"].strip()
                items = split_args(w[1:-1]) if w.startswith("[") else [w]
                conds += [cond_key(i) for i in items]
            if src and re.fullmatch(r"\w+", src) and None not in conds:
                merges.append((m.group(1), src, conds))
            else:
                todo_top.append(st)
            continue
        m = re.match(r"(\w+_ss)\.add\((.*)\)$", st)
        if not m:
            todo_top.append(st)
            continue
        var, args = m.group(1), split_args(m.group(2))
        s = ss(var)
        conds = list(stack)
        if None in conds:
            s.todo.append(st)
            continue
        kw = {}
        pos = []
        for a in args:
            km = re.match(r"(\w+)\s*:\s*(.*)$", a)
            if km:
                kw[km.group(1)] = km.group(2)
            else:
                pos.append(a)
        if "when" in kw:
            w = kw["when"].strip()
            items = split_args(w[1:-1]) if w.startswith("[") else [w]
            keys = [cond_key(i) for i in items]
            if None in keys:
                s.todo.append(st)
                continue
            t = files_of(kw.get("if_true", "")) or []
            f = files_of(kw.get("if_false", "")) or []
            if (kw.get("if_true") and files_of(kw["if_true"]) is None) or \
               (kw.get("if_false") and files_of(kw["if_false"]) is None):
                s.todo.append(st)
                continue
            if f and conds:
                # if_false inside an if block: block condition and not when
                s.add_when(conds + keys, t, [])
                neg = "|".join(k[1:] if k.startswith("!") else "!" + k for k in keys)
                s.add_when(conds + [neg], f, [])
            else:
                s.add_when(conds + keys, t, f)
            continue
        fl = []
        for a in pos:
            f = files_of(a)
            if f is not None:
                fl += f
            elif re.fullmatch(r"\w+", a):
                if a in DEP_LABELS:
                    if DEP_LABELS[a]:
                        s.deps.add(DEP_LABELS[a])
                elif a not in NOT_FOUND:
                    s.todo.append("dependency " + a)
            else:
                s.todo.append(st)
        if conds:
            s.add_when(conds, fl, [])
        else:
            s.srcs += fl
    # fold X.add_all(when: C, if_true: Y) into X, innermost first
    for into, src, conds in reversed(merges):
        if src not in sets:
            continue
        y = sets.pop(src)
        x = ss(into)
        if y.srcs:
            if conds:
                x.add_when(conds, y.srcs, [])
            else:
                x.srcs += y.srcs
        for keys, t, f in y.when:
            if f and conds:
                # if_false under an outer condition: outer and not inner
                x.when.append((conds + keys, t, []))
                neg = "|".join(k[1:] if k.startswith("!") else "!" + k for k in keys)
                x.when.append((conds + [neg], f, []))
            else:
                x.when.append((conds + keys, t, f))
        x.deps |= y.deps
        x.todo += y.todo
    for var, s in sets.items():
        if arch and re.fullmatch(arch + r"(_system)?_ss", var):
            s.arch = arch
    for var in [v for v in sets if v == "user_ss" or v.endswith("_user_ss")]:
        sets.pop(var)   # no user-mode targets are built
    return sets, todo_top, subdirs


def _static_true(key):
    return key in ("have_system", "have_block", "have_tools") or key.startswith("have_system")


def fmt_list(items, indent):
    if not items:
        return "[]"
    if len(items) == 1:
        return f'["{items[0]}"]'
    pad = " " * (indent + 4)
    return "[\n" + "".join(f'{pad}"{i}",\n' for i in items) + " " * indent + "]"


def fmt_cond(keys):
    return f'"{keys[0]}"' if len(keys) == 1 else "[" + ", ".join(f'"{k}"' for k in keys) + "]"


def source_set_macro(var, source_set):
    if source_set.arch or var == "specific_ss":
        return "qemu_target_source_set"
    if var in ("util_ss", "stub_ss", "trace_ss"):
        return "qemu_archive_part"
    return "qemu_source_set"


def fmt_when(keys, if_true, if_false):
    cond = fmt_cond(keys)
    true_files = fmt_list(if_true, 12)
    false_files = fmt_list(if_false, 12)
    args = [cond, true_files] + ([f"if_false = {false_files}"] if if_false else [])
    inline = "        when(" + ", ".join(args) + "),"
    if "\n" not in inline and len(inline) <= 100:
        return inline
    return "        when(\n" + "".join(f"            {arg},\n" for arg in args) + "        ),"


def emit(sets, todo_top, path, subdirs=()):
    d = os.path.dirname(path)
    hs = bool(glob.glob(os.path.join(d, "*.h")))
    incs = bool(glob.glob(os.path.join(d, "*.inc")))
    has_hdrs = hs or incs
    macros = {var: source_set_macro(var, s) for var, s in sets.items()}
    symbols = {"qemu_package", *macros.values()}
    if any(s.when for s in sets.values()):
        symbols.add("when")
    out = []
    if has_hdrs:
        out.append('load("@rules_cc//cc:cc_library.bzl", "cc_library")')
    imports = ", ".join(f'"{symbol}"' for symbol in sorted(symbols))
    out += [f'load("//bazel:qemu.bzl", {imports})', ""]
    out.append(f"# Translated from {path}.")
    if os.path.exists(os.path.join(d, "trace-events")):
        out += ["", 'exports_files(["trace-events"], visibility = ["//:__subpackages__"])']
    if has_hdrs:
        out += ["", "cc_library(", '    name = "headers",', '    visibility = ["//:__subpackages__"],']
        if hs:
            out.append('    hdrs = glob(["*.h"]),')
        if incs:
            out.append('    textual_hdrs = glob(["*.inc"]),')
        out += [")"]
    for t in todo_top:
        out.append(f"# TODO(meson): {t}")
    for var, s in sets.items():
        macro = macros[var]
        archive = macro == "qemu_archive_part"
        out.append("")
        for t in s.todo:
            out.append(f"# TODO(meson): {t}")
        out.append(f"{macro}(" + ("  # of libqemuutil.a" if archive else ""))
        out.append(f'    name = "{var}",')
        if s.srcs:
            out.append(f"    srcs = {fmt_list(s.srcs, 4)},")
        if s.arch:
            out.append(f'    arch = "{s.arch}",')
            if s.common_arch:
                out.append('    kind = "common_arch",')
        elif macro == "qemu_source_set" and var in SYSTEM_SETS:
            out.append('    kind = "system",')
        linkopts = sorted(d for d in s.deps if d.startswith("-l"))
        if linkopts:
            out.append(f"    linkopts = {fmt_list(linkopts, 4)},")
        if not archive:
            out.append('    visibility = ["//:__subpackages__"],')
        if s.when:
            out.append("    when = [")
            out.extend(fmt_when(keys, t, f) for keys, t, f in s.when)
            out.append("    ],")
        deps = ([":headers"] if has_hdrs else []) + sorted(d for d in s.deps if not d.startswith("-l"))
        if deps:
            out.append(f"    deps = {fmt_list(deps, 4)},")
        out.append(")")
    out += ["", "qemu_package(" + (f"subdirs = {fmt_list(list(subdirs), 0)}" if subdirs else "") + ")"]
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    d = sys.argv[1].rstrip("/")
    p = d + "/meson.build"
    sets, todo, subdirs = translate(p)
    sys.stdout.write(emit(sets, todo, p, subdirs))
