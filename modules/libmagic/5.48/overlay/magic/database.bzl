"""Compiles the magic database out of upstream's fragment set."""

def _magic_database_impl(ctx):
    if "/" in ctx.attr.out.name:
        fail(("out must name a file at the package root, not `%s': the fragments are staged in a " +
              "`magic' directory there and the compiler is run in out's own directory, so a nested " +
              "out would see no fragments. Declare this target in the package that should hold the " +
              "database.") % ctx.attr.out.name)

    # src/apprentice.c:2438-2441 tucks each fragment's path, exactly as apprentice_load was
    # handed it, into desc[1] of every entry with an empty description -- 5728 entries, 202
    # distinct `magic/<basename>' strings in the shipped database. So the -m argument is part
    # of the compiled bytes: `-m magic' gives sha256 c2f4e7e5...f268 and `-m ddddd' gives
    # bc0ded08...45fc5, both 10793952 bytes, 28640 of them differing from offset 8369. desc
    # holds 64 bytes and the copy is strlcpy(..., 63), so a path past 62 characters truncates,
    # entries that differed only in that path turn byte-identical, and apprentice_sort's
    # tie-break memcmp (:1136) calls them `Duplicate magic entry' -- 14 such at a 61-character
    # directory name. Hence a directory named exactly `magic', named bare on the command line.
    staged = []
    for fragment in ctx.files.srcs:
        link = ctx.actions.declare_file("magic/" + fragment.basename)
        ctx.actions.symlink(output = link, target_file = fragment)
        staged.append(link)

    ctx.actions.run_shell(
        outputs = [ctx.outputs.out],
        inputs = staged,
        tools = [ctx.executable.compiler],
        # -C writes the basename of -m with .mgc appended, relative to the process CWD
        # and nowhere else (src/apprentice.c:3482 calls mkdbname with strip=1), so the
        # action runs in the directory that wants the file.
        command = 'compiler="$PWD/%s" && cd %s && exec "$compiler" -C -m magic' % (
            ctx.executable.compiler.path,
            ctx.outputs.out.dirname,
        ),
        mnemonic = "CompileMagicDatabase",
        progress_message = "Compiling %{output}",
        use_default_shell_env = False,
    )

    return DefaultInfo(files = depset([ctx.outputs.out]))

magic_database = rule(
    implementation = _magic_database_impl,
    doc = """Compiles `srcs' into `out', reproducing magic/Makefile.am:388-403.""",
    attrs = {
        "compiler": attr.label(executable = True, cfg = "exec", mandatory = True),
        "out": attr.output(mandatory = True),
        "srcs": attr.label_list(allow_files = True),
    },
)
