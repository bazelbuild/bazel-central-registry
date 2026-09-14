use strict;
use warnings;

# Runs libvpx's RTCD Perl generators and captures their stdout to the declared
# output file.

sub _script_path_for_do {
    my ($script) = @_;
    return $script if $script =~ m{^(?:/|[A-Za-z]:[\\/])};
    return "./" . $script;
}

my ($out, $script, @script_args) = @ARGV;

open my $stdout, ">", $out or die "open($out): $!";
local *STDOUT = $stdout;
local @ARGV = @script_args;

my $script_to_run = _script_path_for_do($script);
local $0 = $script;
my $rv = do $script_to_run;
die $@ if $@;
die "do($script) failed: $!" unless defined $rv;

close $stdout or die "close($out): $!";
