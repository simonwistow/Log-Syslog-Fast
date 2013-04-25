use strict;
use warnings;

our $CLASS = 'Log::Syslog::Fast';
use Log::Syslog::Constants ':all';
use Log::Syslog::Fast::PP qw(:protos :formats);
use Log::Syslog::Fast;

require 't/07-tls.pl';

# my $logger = eval { Log::Syslog::Fast->new(LOG_UDP, 'localhost', 514, $facility1, $severity1, $sender1, $name1, 1, SSL_verify_mode => 0x0) };
# like($@, qr/ssl not supported/, "Can't do SSL");