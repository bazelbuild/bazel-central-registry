"""Custom rule to generate colordiff entrypoint with runfile-resolved diff_cmd."""

def _rlocationpath(file, workspace_name):
    if file.short_path.startswith("../"):
        return file.short_path[len("../"):]

    return "{}/{}".format(workspace_name, file.short_path)

_TEMPLATE = """\
#!/usr/bin/perl

use Runfiles;

my $cmp_rlocation = "{cmp_rlocation}";
my $diff_rlocation = "{diff_rlocation}";
my $diff3_rlocation = "{diff3_rlocation}";
my $sdiff_rlocation = "{sdiff_rlocation}";

my $r = Runfiles->create();

my $cmp_runfile = $r->rlocation($cmp_rlocation);
my $diff_runfile = $r->rlocation($diff_rlocation);
my $diff3_runfile = $r->rlocation($diff3_rlocation);
my $sdiff_runfile = $r->rlocation($sdiff_rlocation);

my %runfile_cmd = (
    "cmp" => $cmp_runfile,
    "diff" => $diff_runfile,
    "diff3" => $diff3_runfile,
    "sdiff" => $sdiff_runfile,
);
my $diff_cmd = $diff_runfile;
"""

def _colordiff_script_impl(ctx):
    workspace_name = ctx.workspace_name

    out = ctx.outputs.out
    ctx.actions.expand_template(
        template = ctx.file.template,
        output = out,
        substitutions = {
            "#!/usr/bin/perl": _TEMPLATE.format(
                cmp_rlocation = _rlocationpath(ctx.executable.cmd_cmp, workspace_name),
                diff_rlocation = _rlocationpath(ctx.executable.cmd_diff, workspace_name),
                diff3_rlocation = _rlocationpath(ctx.executable.cmd_diff3, workspace_name),
                sdiff_rlocation = _rlocationpath(ctx.executable.cmd_sdiff, workspace_name),
            ),
            "$diff_cmd = $value;": "$diff_cmd = exists $runfile_cmd{$value} ? $runfile_cmd{$value} : $value;",
            "my $diff_cmd     = \"diff\";": "# my $diff_cmd     = \"diff\";",
        },
        is_executable = False,
    )

    return DefaultInfo(files = depset([out]))

colordiff_script = rule(
    doc = "Expands a colordiff template with diff binary runfile paths substituted.",
    implementation = _colordiff_script_impl,
    attrs = {
        "cmd_cmp": attr.label(
            doc = "The cmp binary (e.g. @diffutils//:cmp)",
            mandatory = True,
            executable = True,
            cfg = "target",
        ),
        "cmd_diff": attr.label(
            doc = "The diff binary target (e.g. @diffutils//:diff)",
            mandatory = True,
            executable = True,
            cfg = "target",
        ),
        "cmd_diff3": attr.label(
            doc = "The diff3 binary (e.g. @diffutils//:diff3)",
            mandatory = True,
            executable = True,
            cfg = "target",
        ),
        "cmd_sdiff": attr.label(
            doc = "The sdiff binary (e.g. @diffutils//:sdiff)",
            mandatory = True,
            executable = True,
            cfg = "target",
        ),
        "out": attr.output(
            doc = "Name of the generated script file.",
            mandatory = True,
        ),
        "template": attr.label(
            mandatory = True,
            allow_single_file = [".pl"],
            doc = "The `colordiff` source file.",
        ),
    },
)
