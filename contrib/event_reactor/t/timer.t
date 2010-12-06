#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
use Time::HiRes 'usleep';

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'EventReactor::Timer';

my $t;

my $cb = 0;
$t = EventReactor::Timer->new(
    interval => 0.1,
    one_shot => 1,
    cb       => sub { $cb = 1 }
);
ok $t->one_shot;
usleep 110_000;
ok $t->wake_up;
is $cb => 1;
usleep 110_000;
ok !$t->wake_up;

$cb = 0;
$t = EventReactor::Timer->new(
    interval => 0.1,
    cb       => sub { $cb++ }
);
ok !$t->one_shot;
usleep 110_000;
ok $t->wake_up;
is $cb => 1;
usleep 110_000;
ok $t->wake_up;
is $cb => 2;
