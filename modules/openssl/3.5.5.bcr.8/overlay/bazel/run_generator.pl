# Runs one of OpenSSL's Perl generator scripts (util/mkerr.pl,
# crypto/objects/objects.pl, ...) in-process, with a fixed clock, writing to
# stdout like the upstream build does (see util/file-from-stdout.pl).
#
# Some scripts stamp the current year into their output: util/mkerr.pl calls
# localtime() directly, others go through OpenSSL::copyright (which honours
# OSSL_COPYRIGHT_YEAR). Perl lets a program replace the built-in localtime()
# before the script is compiled, so when SOURCE_DATE_EPOCH is set the clock
# is pinned to it and the output no longer depends on when it ran.
#
# Usage: run_generator.pl <script.pl> <script arguments...>

use strict;
use warnings;
use File::Spec;

BEGIN {
    my $epoch = $ENV{SOURCE_DATE_EPOCH};
    if (defined $epoch) {
        no warnings qw(redefine once);
        *CORE::GLOBAL::localtime = sub {
            return @_ ? CORE::localtime($_[0]) : CORE::localtime($epoch);
        };
    }
}

my $script = shift @ARGV
    or die "usage: $0 <script.pl> <arguments...>\n";
# `do FILE` searches @INC for a bare relative path rather than the current
# directory, so make the path explicit; $0 keeps FindBin-based scripts honest.
$script = File::Spec->rel2abs($script);
$0 = $script;
my $ok = do $script;
die "$script: $@" if $@;
die "$script: $!" if !defined $ok && $!;
