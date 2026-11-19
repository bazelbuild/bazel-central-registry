use strict;
use warnings;
use IPC::Open2 qw(open2);
use Test::More;
use Test::Nginx;

my $t = Test::Nginx->new()->plan(2);
my $dir = $t->testdir();
my $openssl = $ENV{TEST_OPENSSL};
$ENV{OPENSSL_CONF} = "$dir/openssl.cnf";
$t->write_file('openssl.cnf', "[req]\ndistinguished_name=dn\n[dn]\n");
system($openssl, 'req', '-x509', '-newkey', 'ec', '-pkeyopt', 'ec_paramgen_curve:P-256',
    '-noenc', '-days', '1', '-subj', '/CN=localhost', '-addext', 'subjectAltName=DNS:localhost',
    '-keyout', "$dir/key.pem", '-out', "$dir/cert.pem") == 0 or die 'openssl req failed';

$t->write_file_expand('nginx.conf', <<'EOF')->run();
%%TEST_GLOBALS%%
daemon off;
events {}
http {
    %%TEST_GLOBALS_HTTP%%
    server {
        listen 127.0.0.1:8080 ssl;
        listen 127.0.0.1:%%PORT_8081_UDP%% quic;
        http3 on;
        ssl_certificate %%TESTDIR%%/cert.pem;
        ssl_certificate_key %%TESTDIR%%/key.pem;
        location / { return 200 "$ssl_protocol"; }
    }
}
EOF

my $pid = open2(my $response, my $request, $openssl, 's_client', '-quiet', '-tls1_3',
    '-connect', '127.0.0.1:' . port(8080), '-servername', 'localhost',
    '-verify_return_error', '-verify_hostname', 'localhost', '-CAfile', "$dir/cert.pem");
print {$request} "GET / HTTP/1.0\r\nHost: localhost\r\nConnection: close\r\n\r\n";
close $request;
my $http = do { local $/; <$response> };
close $response;
waitpid($pid, 0);
is($?, 0, 'OpenSSL verifies the nginx TLS certificate');
like($http, qr{HTTP/1\.[01] 200 OK\r\n.*\r\n\r\nTLSv1\.3$}s, 'serves HTTPS with the QUIC listener enabled');
