package lcov_pure_perl;

# Preloaded by the lcov tools (perl_binary.perlopt = ["-Mlcov_pure_perl"])
# under --@rules_perl//perl/settings:xs=false, which on Linux resolves a perl
# without dynamic loading.
#
# DateTime ships XS with a pure-Perl fallback that engages when the XS fails
# to load with "Can't locate loadable object". A perl without dynamic loading
# fails with a different message, which DateTime rethrows. Sub::Identify,
# which namespace::autoclean pulls in, does the same. Both honour a variable
# asking for the pure-Perl implementation up front. With the flag on nothing
# is preloaded and the tools run as they always have.
BEGIN {
    $ENV{PERL_DATETIME_PP}     = 1;
    $ENV{PERL_SUB_IDENTIFY_PP} = 1;
}

1;
