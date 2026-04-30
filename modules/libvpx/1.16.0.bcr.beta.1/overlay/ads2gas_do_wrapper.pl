use strict;
use warnings;

# Runs libvpx's ads2gas conversion with the input asm file connected to stdin,
# then rewrites the generated vpx_config.asm include to the relative path that
# Bazel's generated output tree expects.

sub _script_path_for_do {
    my ($script) = @_;
    return $script if $script =~ m{^(?:/|[A-Za-z]:[\\/])};
    return "./" . $script;
}

my ($out, $script, $stdin_src, $config_include, @script_args) = @ARGV;
my $replacement = ".include \"" . $config_include . "vpx_config.asm\"";

open my $in, "<", $stdin_src or die "open($stdin_src): $!";
local *STDIN = $in;
open my $stdout, ">", $out or die "open($out): $!";
local *STDOUT = $stdout;
local @ARGV = @script_args;

my $script_to_run = _script_path_for_do($script);
local $0 = $script;
my $rv = do $script_to_run;
die $@ if $@;
die "do($script) failed: $!" unless defined $rv;

close $stdout or die "close($out): $!";
close $in or die "close($stdin_src): $!";

open my $read, "<", $out or die "open($out): $!";
local $/;
my $content = <$read>;
close $read or die "close($out): $!";

$content =~ s#\.include "\./vpx_config\.asm"#$replacement#g;

open my $write, ">", $out or die "open($out): $!";
print {$write} $content or die "write($out): $!";
close $write or die "close($out): $!";
