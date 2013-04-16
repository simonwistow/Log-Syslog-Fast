use Test::More tests => 1;

SKIP: {
    skip 'Need to write an SSL server that forks', 1;

    ok(1, "SSL works");
}

# vim: filetype=perl
1;
