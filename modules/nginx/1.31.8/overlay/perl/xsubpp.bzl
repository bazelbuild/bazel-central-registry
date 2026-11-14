"""Translate XS with the Perl interpreter selected for the execution platform."""

def _xsubpp_impl(ctx):
    perl = ctx.toolchains["@rules_perl//perl:exec_toolchain_type"].perl_runtime
    out = ctx.actions.declare_file(ctx.label.name + ".c")
    args = ctx.actions.args()

    # ParseXS changes directory. Resolve @INC and typemaps before it does so.
    args.add("-e")
    args.add("""BEGIN { use File::Spec; @INC = map { ref($_) ? $_ : File::Spec->rel2abs($_) } @INC }
use ExtUtils::ParseXS;
my ($xs, $out, @map) = @ARGV;
my $xspp = ExtUtils::ParseXS->new;
$xspp->process_file(filename => $xs, output => $out,
    prototypes => 0, linenumbers => 0, typemap => [map { File::Spec->rel2abs($_) } @map]);
exit($xspp->report_error_count ? 1 : 0);""")
    args.add(ctx.file.src)
    args.add(out)
    args.add_all(ctx.files.typemaps)
    ctx.actions.run(
        executable = perl.interpreter,
        arguments = [args],
        inputs = depset([ctx.file.src] + ctx.files.typemaps, transitive = [perl.runtime]),
        outputs = [out],
        mnemonic = "PerlXS",
        toolchain = "@rules_perl//perl:exec_toolchain_type",
    )
    return [DefaultInfo(files = depset([out]))]

perl_xsubpp = rule(
    implementation = _xsubpp_impl,
    attrs = {
        "src": attr.label(allow_single_file = [".xs"], mandatory = True),
        "typemaps": attr.label_list(allow_files = True),
    },
    toolchains = ["@rules_perl//perl:exec_toolchain_type"],
)
