#!perl -w
########
#
# Usage: loggly.pl <loggly port> <msg> [ssl]
#
########
use strict;
use warnings;
use Log::Syslog::Fast qw(:all);
use Log::Syslog::Fast::PP;
use Sys::Hostname qw(hostname);
use IO::Socket::SSL qw(debug4);
use FindBin qw($Bin);

my $port   = shift;
my $msg    = shift || die "You must pass in a message\n";
my @ssl    = ();
my $proto  = LOG_UDP;

if ($ARGV[0]==2) {
    $proto  = LOG_TCP;
    @ssl    = (1, Timeout => 2, SSL_ca_file => "$Bin/certs/loggly_full.crt", SSL_cert_file => "$Bin/certs/client-cert.pem", SSL_key_file => "$Bin/certs/client-key.pem");
    $msg   .= " - TLS";
} elsif ($ARGV[0]==1) {
    $proto  = LOG_TCP;
    $msg   .= " - TCP";
} else {
    $msg   .= " - UDP";   
}

my $logger = Log::Syslog::Fast::PP->new($proto, 'logs.loggly.com', $port, LOG_LOCAL3, LOG_CRIT, hostname, "loggly_logger", @ssl);
print "Sent: ".$logger->send($msg, time)."\n";