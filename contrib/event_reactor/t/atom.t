#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 12;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'EventReactor::Atom';

my $atom;
my $written;

$atom    = EventReactor::Atom->new;
$written = 0;
$atom->write('foo' => sub { $written = 1 });
ok !$written;
$atom->bytes_written(1);
ok !$written;
$atom->bytes_written(2);
ok $written;
is $atom->is_writing => 0;

$atom    = EventReactor::Atom->new;
$written = 0;
$atom->write('foo' => sub { $written++ });
$atom->write('bar' => sub { $written++ });
ok !$written;
$atom->bytes_written(1);
ok !$written;
$atom->bytes_written(5);
is $written          => 2;
is $atom->is_writing => 0;

$atom    = EventReactor::Atom->new;
$written = 0;
$atom->write('foo' => sub { $written++ });
$atom->bytes_written(10);
is $written          => 1;
is $atom->is_writing => 0;

$atom    = EventReactor::Atom->new;
$written = 0;
$atom->write('foo');
$atom->bytes_written(3);
is $atom->is_writing => 0;
