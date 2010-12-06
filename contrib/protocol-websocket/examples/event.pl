#!/usr/bin/env perl

use strict;
use warnings;

use Event qw(time);
require Event::io;
use IO::Socket::INET;

my $socket = IO::Socket::INET->new(
    LocalAddr => 'localhost',
    LocalPort => 3000,
    Listen    => 1,
    Blocking  => 0
);

$socket->blocking(0);

Event->io(
    fd      => $socket,
    timeout => 0.1,
    poll    => "r",
    repeat  => 1,
    cb      => sub {
        my $e   = shift;
        my $got = $e->got;

        if ($got eq "r") {
            sysread(STDIN, my $buf, 80);
            chop $buf;

            my $len = length($buf);
            Event::unloop if !$len;

            print "read[$len]:$buf:\n";
        }
    }
);

Event::loop;
