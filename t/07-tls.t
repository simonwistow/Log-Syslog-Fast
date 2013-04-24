use strict;
use warnings;

#use Log::Syslog::Fast ':all';
# use Test::More tests => 1;
# 
# my $facility1 = LOG_AUTH;
# my $severity1 = LOG_INFO;
# my $sender1   = 'calvin';
# my $name1     = 'popsicle';
# my $pid1      = $$;

our $CLASS = 'Log::Syslog::Fast';
use Log::Syslog::Constants ':all';
use Log::Syslog::Fast qw(:protos :formats);

require 't/07-tls.pl';

# my $logger = eval { Log::Syslog::Fast->new(LOG_UDP, 'localhost', 514, $facility1, $severity1, $sender1, $name1, 1, SSL_verify_mode => 0x0) };
# like($@, qr/ssl not supported/, "Can't do SSL");