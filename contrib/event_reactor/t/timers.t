#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use EventReactor;

my $event_reactor = EventReactor->new(
    address => 'localhost',
    port    => 3000,
)->listen;

my $timers = 0;

$event_reactor->set_timeout(
    0.1 => sub {
        $timers++;
    }
);

$event_reactor->set_timeout(
    0.2 => sub {
        $timers++;

        $event_reactor->stop;
    }
);

$event_reactor->start;

is $timers                        => 2;
is keys %{$event_reactor->timers} => 0;
