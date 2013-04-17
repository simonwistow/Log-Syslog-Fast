#!perl -w
########
#
# Usage: papertrail.pl <papertrail port> <msg> [ssl]
#
########
use strict;
use warnings;
use Log::Syslog::Fast qw(:all);
use Log::Syslog::Fast::PP;
use Sys::Hostname qw(hostname);
use IO::Socket::SSL qw(debug3);

my $port   = shift || die "You must pass in your PaperTrail port number\n";
my $msg    = shift || die "You must pass in a message\n";
#my @ssl    = !$ARGV[0] ? ( ) : (1, SSL_cert_file => 'syslog.papertrail.crt', Timeout => 2, SSL_use_cert => 0);
my @ssl    = ();
my $proto  = LOG_UDP;

if ($ARGV[0]) {
    $proto  = LOG_TCP;
    @ssl    = (1, Timeout => 2, SSL_cert_file => 'syslog.papertrail.crt');
    $msg   .= " - TCP";
} else {
    $msg   .= " - UDP";    
}

my $logger = Log::Syslog::Fast::PP->new($proto, 'logs.papertrailapp.com', $port, LOG_LOCAL3, LOG_CRIT, hostname, "papertrail_logger", @ssl);
print "Sent: ".$logger->send($msg, time)."\n";