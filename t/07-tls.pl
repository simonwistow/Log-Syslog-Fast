use Test::More tests => 73;
use File::Temp 'tempdir';
use IO::Select;
use IO::Socket::INET;

use POSIX 'strftime';

require 't/lib/LSFServer.pm';

my $test_dir = tempdir(CLEANUP => 1);

sub listen_port {
    return 8080;
}

my %servers;

eval 'use IO::Socket::SSL;';

SKIP: {
   if ($@) {
       skip 'Cannot run TLS tests without IO::Socket::SSL', 73;
   }


%servers = (
    tcp => sub {
        my $listener = IO::Socket::SSL->new(
            LocalHost       => 'localhost',
            LocalPort       => listen_port(),
            Listen          => 5,
            Reuse           => 1,
            SSL_verify_mode => SSL_VERIFY_NONE,
            SSL_ca_file     => "t/certs/test-ca.pem",
            SSL_key_file    => "t/certs/client-key.pem",
        ) or die $!;
        return StreamServer->new(
            listener    => $listener,
            proto       => LOG_TCP,
            address     => [$listener->sockhost, $listener->sockport],
            ssl         => 1,
        );
    },
);

# strerror(3) messages on linux in the "C" locale are included below for reference

my @params = (LOG_AUTH, LOG_INFO, 'localhost', 'test', 1, SSL_verify_mode => SSL_VERIFY_NONE);

for my $proto (LOG_TCP, LOG_UDP) {
    eval { $CLASS->new($proto, '%^!/0', 0, @params) };
    like($@, qr/^Error in ->new/, "$proto: bad ->new call throws an exception");
}

for my $p (sort keys %servers) {
    my $listen = $servers{$p};

    # basic behavior
    eval {
        my $server = $listen->();
        ok($server->{listener}, "$p: listen") or diag("listen failed: $!");

        my $logger = $server->connect($CLASS => @params);
        ok($logger, "$p: ->new returns something");
        is(ref $logger, $CLASS, "$p: ->new returns a $CLASS object");

        my $receiver = $server->accept;
        ok($receiver, "$p: accepted");

        my $time = time;
        for my $config (['without time'], ['with time', $time]) {
            my ($msg, @extra) = @$config;

            my @payload_params = (@params, $$, $msg, $time);
            my $expected = expected_payload(@payload_params);

            my $sent = eval { $logger->send($msg, @extra) };
            ok(!$@, "$p: ->send $msg doesn't throw");
            is($sent, length $expected, "$p: ->send $msg sent whole payload");

            my $found = wait_for_readable($receiver);
            ok($found, "$p: didn't time out while waiting for data $msg");

            if ($found) {
                $receiver->recv(my $buf, 256);

                ok($buf =~ /^<38>/, "$p: ->send $msg has the right priority");
                ok($buf =~ /$msg$/, "$p: ->send $msg has the right message");
                ok(payload_ok($buf, @payload_params), "$p: ->send $msg has correct payload");
            }
        }
    };
    diag($@) if $@;

    # write accessors
    eval {

        my $server = $listen->();
        my $logger = $server->connect($CLASS => @params);

        # ignore first connection for stream protos since reconnect is expected
        $server->accept();

        eval {
            # this method triggers a reconnect for stream protocols
            $logger->set_receiver($server->proto, $server->address);
        };
        ok(!$@, "$p: ->set_receiver doesn't throw");

        eval { $logger->set_priority(LOG_NEWS, LOG_CRIT) };
        ok(!$@, "$p: ->set_priority doesn't throw");

        eval { $logger->set_sender('otherhost') };
        ok(!$@, "$p: ->set_sender doesn't throw");

        eval { $logger->set_name('test2') };
        ok(!$@, "$p: ->set_name doesn't throw");

        eval { $logger->set_pid(12345) };
        ok(!$@, "$p: ->set_pid doesn't throw");

        my $receiver = $server->accept;

        my $msg = "testing 3";
        my @payload_params = (LOG_NEWS, LOG_CRIT, 'otherhost', 'test2', 12345, $msg, time);
        my $expected = expected_payload(@payload_params);

        my $sent = eval { $logger->send($msg) };
        ok(!$@, "$p: ->send after accessors doesn't throw");
        is($sent, length $expected, "$p: ->send sent whole payload");

        my $found = wait_for_readable($receiver);
        ok($found, "$p: didn't time out while listening");

        if ($found) {
            $receiver->recv(my $buf, 256);
            ok($buf, "$p: send after set_receiver went to correct port");
            ok($buf =~ /^<58>/, "$p: ->send after set_priority has the right priority");
            ok($buf =~ /otherhost/, "$p: ->send after set_sender has the right sender");
            ok($buf =~ /test2\[/, "$p: ->send after set_name has the right name");
            ok($buf =~ /\[12345\]/, "$p: ->send after set_name has the right pid");
            ok($buf =~ /$msg$/, "$p: ->send after accessors sends right message");
            ok(payload_ok($buf, @payload_params), "$p: ->send $msg has correct payload");
        }
    };
    diag($@) if $@;

    # test failure behavior when server is unreachable
    eval {

        # test when server is initially available but goes away
        my $server = $listen->();
        my $logger = $server->connect($CLASS => @params);
        $server->close();

        my $piped = 0;
        local $SIG{PIPE} = sub { $piped++ };
        eval { $logger->send("testclosed") };
        if ($p eq 'tcp') {
            # "Connection reset by peer" on linux, sigpipe on bsds
            ok($@ || $piped, "$p: ->send throws on server close");
        }
        elsif ($p eq 'udp') {
            ok(!$@, "$p: ->send doesn't throw on server close");
        }

        # test when server is not initially available

        # increment peer port to get one that (probably) wasn't recently used;
        # otherwise UDP/ICMP business doesn't work right on at least linux 2.6.18
        $server->{address}[1]++;

        if ($p eq 'udp') {
            # connectionless udp should fail on 2nd call to ->send, after ICMP
            # error is noticed by kernel

            my $logger = $server->connect($CLASS => @params);
            ok($logger, "$p: ->new doesn't throw on connect to missing server");

            for my $n (1..2) {
                eval { $logger->send("test$n") };
                ok(!$@, "$p: odd ->send to missing server doesn't throw");

                eval { $logger->send("test$n") };
                # "Connection refused"
                like($@, qr/Error while sending/, "$p: even ->send to missing server does throw");
            }
        }
        else {
            # connected protocols should fail on connect, i.e. ->new
            eval { $CLASS->new($server->proto, $server->address, @params); };
            like($@, qr/^Error in ->new/, "$p: ->new throws on connect to missing server");
        }
    };
    diag($@) if $@;
}

# check that bad methods are reported for the caller
eval {
    my $logger = $CLASS->new(LOG_UDP, '::1', 514, LOG_LOCAL0, LOG_INFO, "mymachine", "logger");
    $logger->nonexistent_method();
};
like($@, qr{at t/07-tls.}, 'error in caller'); # not Fast.pm

sub expected_payload {
    my ($facility, $severity, $sender, $name, $pid, $msg, $time) = @_;
    return sprintf "<%d>%s %s %s[%d]: %s",
        ($facility << 3) | $severity,
        strftime("%h %e %T", localtime($time)),
        $sender, $name, $pid, $msg;
}

sub payload_ok {
    my ($payload, @payload_params) = @_;
    for my $offset (0, -1, 1) {
        my $allowed = expected_payload(@payload_params);
        return 1 if $allowed eq $payload;
    }
    return 0;
}

sub allowed_payloads {
    my @params = @_;
    my $time = pop @params;
    return map { expected_payload(@params, $time + $_) } (-1, 0, 1);
}

# use select so test won't block on failure
sub wait_for_readable {
    my $sock = shift;
    return IO::Select->new($sock)->can_read(1);
}
}

# vim: filetype=perl
1;
