function add(set, list, name,    n, a, i) {
    n = split(list, a, ",")
    for (i = 1; i <= n; i++)
        set[a[i]] = name
}

# list holds SYMBOL=MACRO entries.
function add_macros(set, list,    n, a, i, pair) {
    n = split(list, a, ",")
    for (i = 1; i <= n; i++) {
        split(a[i], pair, "=")
        set[pair[1]] = pair[2]
    }
}

function describe(macro) {
    return macro == "" ? "without a macro" : "where " macro " is defined"
}

function compare(var, list, optional, upstream, upstream_macro, fork, fork_macro,    s) {
    for (s in upstream)
        if (!(s in fork)) {
            printf "%s: configure.ac adds %s to %s; add it to %s or %s in include/jemalloc/internal/symbols.bzl\n", upstream[s], s, var, list, optional
            failed = 1
        } else if (upstream_macro[s] != fork_macro[s]) {
            printf "%s: configure.ac adds %s to %s %s, but include/jemalloc/internal/symbols.bzl lists it %s\n", upstream[s], s, var, describe(upstream_macro[s]), describe(fork_macro[s])
            failed = 1
        }
    for (s in fork)
        if (!(s in upstream)) {
            printf "%s lists %s, which configure.ac never adds to %s\n", fork[s], s, var
            failed = 1
        }
}

BEGIN {
    PROCINFO["sorted_in"] = "@ind_str_asc"
    add(fork_public, public, "PUBLIC_SYMBOLS")
    add(fork_wrap, wrap, "WRAP_SYMBOLS")
    add_macros(fork_public_macro, public_macros)
    add_macros(fork_wrap_macro, wrap_macros)
}

# configure.ac appends an optional symbol in the branch that defines its macro: the last AC_DEFINE since the branch
# opened. A line that opens, separates or closes a branch forgets it.
/^[[:space:]]*(if|elif|else|fi|case|esac|;;)([^A-Za-z0-9_]|$)/ {
    macro = ""
}

match($0, /AC_DEFINE\(\[([A-Za-z0-9_]+)\]/, d) {
    macro = d[1]
}

match($0, /^[[:space:]]*(public|wrap)_syms="([^"]*)"/, m) {
    n = split(m[2], tokens, /[[:space:]]+/)
    appends = index(m[2], "${" m[1] "_syms}") > 0
    for (i = 1; i <= n; i++) {
        t = tokens[i]
        if (t == "" || t == "${" m[1] "_syms}")
            continue
        sub(/\$\{jemalloc_version_gid\}/, gid, t)
        if (t ~ /\$/) {
            printf "%s:%d: cannot interpret %s in %s_syms\n", FILENAME, FNR, t, m[1]
            failed = 1
        } else if (m[1] == "public") {
            upstream_public[t] = FILENAME ":" FNR
            upstream_public_macro[t] = appends ? macro : ""
        } else {
            upstream_wrap[t] = FILENAME ":" FNR
            upstream_wrap_macro[t] = appends ? macro : ""
        }
    }
    next
}

/(public|wrap)_syms=/ && !/^[[:space:]]*wrap_syms=$/ && !/^[[:space:]]*public_syms=`for sym in \$\{public_syms\}; do echo "\$\{sym\}"; done \|grep -v / {
    printf "%s:%d: cannot interpret %s\n", FILENAME, FNR, $0
    failed = 1
}

END {
    if (length(upstream_public) == 0 || length(upstream_wrap) == 0) {
        printf "%s: found no public_syms or wrap_syms assignments\n", FILENAME
        exit 1
    }
    compare("public_syms", "PUBLIC_SYMBOLS", "OPTIONAL_PUBLIC_SYMBOLS", upstream_public, upstream_public_macro, fork_public, fork_public_macro)
    compare("wrap_syms", "WRAP_SYMBOLS", "OPTIONAL_WRAP_SYMBOLS", upstream_wrap, upstream_wrap_macro, fork_wrap, fork_wrap_macro)
    exit failed
}
