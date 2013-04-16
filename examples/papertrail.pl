#!perl -w
########
#
# Usage: papertrail.pl <papertrail port> <msg> [ssl]
#
########
use strict;
use warnings;
use Log::Syslog::Fast::PP qw(:all);
use Sys::Hostname qw(hostname);

my $port   = shift || die "You must pass in your PaperTrail port number\n";
my $msg    = shift || die "You must pass in a message\n";
my @ssl    = !$_[0] ? ( ) : (1, SSL_cert_file => 'syslog.papertrail.crt');

my $logger = Log::Syslog::Fast::PP->new(LOG_UDP, 'logs.papertrailapp.com', $port, LOG_LOCAL0, LOG_CRIT, hostname, "papertrail_logger", @ssl);
print "Sent: ".$logger->send($msg)."\n";
