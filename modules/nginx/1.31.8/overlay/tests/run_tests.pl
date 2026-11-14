use strict;
use warnings;
use File::Basename qw(dirname);
use File::Spec;
use TAP::Harness;

# nginx-tests changes directory before reading TEST_NGINX_BINARY.
my ($nginx, $test_nginx_pm, $nginx_pm, $strict_pm, $config_pm, $openssl, @tests) =
    map { File::Spec->rel2abs($_) } @ARGV;
$ENV{TEST_NGINX_BINARY} = $nginx;
$ENV{TEST_NGINX_MODULES} = dirname($nginx);
$ENV{TMPDIR} = $ENV{TEST_TMPDIR};
$ENV{TEST_OPENSSL} = $openssl;

# nginx initializes the embedded interpreter when it loads ngx_http_perl_module.
my $perl5lib = join(':', map { dirname($_) } ($nginx_pm, $strict_pm, $config_pm));
$ENV{TEST_NGINX_GLOBALS} = qq{env PERL5LIB=$perl5lib;\n};

# A root worker would drop privileges before opening the test's private files.
$ENV{TEST_NGINX_GLOBALS} .= "user root " . getgrgid(0) . ";\n" if $> == 0;

my $lib = dirname(dirname($test_nginx_pm));
my $result = TAP::Harness->new({ exec => [$^X, "-I$lib"] })->runtests(@tests);
exit 1 if $result->has_errors;
for my $test (@tests) {
    my ($parser) = $result->parsers($test);
    die "No assertions ran in $test\n" unless $parser->tests_run;
}
