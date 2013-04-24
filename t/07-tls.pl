use Test::More tests => 1;

SKIP: {
    my $reason = ("Log::Syslog::Fast" eq $CLASS) ? "You may need to install openssl and then reinstall" 
                                                 : "You may need to install IO::Socket::SSL";
    skip "$CLASS doesn't support SSL - $reason", 1 unless $CLASS->can_ssl;
    skip 'Need to write an SSL server that forks', 1;

    ok(1, "SSL works");
}

# vim: filetype=perl
1;
