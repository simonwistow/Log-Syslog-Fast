use strict;
our $CLASS = $CLASS;

use FindBin qw($Bin);
use Test::More tests => 3;
use IO::Socket::SSL;# qw(debug4);

# old IO::Socket::INET fails with "Bad service '0'" when attempting to use
# wildcard port
my $port = 24767;
sub listen_port {
    return 0 if $IO::Socket::INET::VERSION >= 1.31;
    diag("Using port $port for IO::Socket::INET v$IO::Socket::INET::VERSION");
    return $port++;
}


require 't/lib/LSFServer.pm';
SKIP: {
    my $need = ($CLASS eq 'Log::Syslog::Fast') ? "OpenSSL and recompile" : "IO::Socket::SSL";
    skip "SSL not supported for $CLASS. You may need to install $need", 3 unless $CLASS->can_tls;

    my $listener = IO::Socket::SSL->new(
        Proto           => 'tcp',
        LocalHost       => '127.0.0.1',
        LocalPort       => listen_port(),
        Listen          => 5,
        Reuse           => 1,
        SSL_server      => 1,
        SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE(),
        SSL_ca_file     => "$Bin/certs/test-ca.pem",
        SSL_key_file    => "$Bin/certs/client-key.pem",
        SSL_cert_file   => "$Bin/certs/client-cert.pem",
    );


    my $server = StreamServer->new(
         listener    => $listener,
         proto       => LOG_TLS,
         address     => [$listener->sockhost, $listener->sockport],
     );

    # create server
    ok($server, "Server Initialization");


    skip "Fork not implemented on this platform", 2 if ( grep { $^O =~m{$_} } qw( MacOS VOS vmesa riscos amigaos ) );

    # then connect to it from a child
    defined( my $pid = fork() ) || die $!;
    if ( $pid == 0 ) {
        $server->close;
        my $logger = $server->connect($CLASS => LOG_LOCAL3, LOG_CRIT, 'localhost', "testlogger", SSL_ca_file => "$Bin/certs/test-ca.pem");
        $logger->send("Hello") if $logger;
        exit;
    } 

    my $receiver = $server->accept;
    ok($receiver, "Server accepted");
    kill(9,$pid) unless $receiver;

    my $msg = <$receiver>;
    like($msg, qr/Hello$/, "Got correct message");
    close($receiver);
    wait;
}
1;
