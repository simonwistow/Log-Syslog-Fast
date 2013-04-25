#!perl -w
########
#
# Usage: papertrail.pl <papertrail port> <msg> [ssl]
#
########
use strict;
use warnings;
use lib qw(../lib);
use Log::Syslog::Fast qw(:all);
use Log::Syslog::Fast::PP;
use Sys::Hostname qw(hostname);
use IO::Socket::SSL qw(debug4);
use FindBin qw($Bin);


my $port   = shift;
my $msg    = shift || die "You must pass in a message\n";
my %ssl    = ( SSL_ca_file => => "$Bin/certs/syslog.papertrail.crt", SSL_check_crl => 0); # , SSL_cert_file => 'certs/client-cert.pem', SSL_key_file => 'certs/client-key.pem' );
my $proto  = LOG_UDP;

if ($ARGV[0]==2) {
    $proto  = LOG_TLS;
    $msg   .= " - TLS";
} elsif ($ARGV[0]==1) {
    $proto  = LOG_TCP;
    $msg   .= " - TCP";
} else {
    $msg   .= " - UDP";    
}

my $logger = Log::Syslog::Fast::PP->new($proto, 'logs.papertrailapp.com', $port, LOG_LOCAL3, LOG_CRIT, hostname, "papertrail_logger", %ssl);
#$logger->set_format(LOG_RFC5424);
print "Sent: ".$logger->send($msg, time)."\n";