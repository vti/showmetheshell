#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 15;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator::Server';

use EventReactor::AcceptedAtom;

my $handshake;

my $atom = EventReactor::AcceptedAtom->new;
my $s    = ReAnimator::Server->new(
    atom         => $atom,
    on_handshake => sub { $handshake++ }
);

$atom->accepted;
ok $atom->read("GET /demo HTTP/1.1\x0d\x0a");
ok $atom->read("Upgrade: WebSocket\x0d\x0a");
ok $atom->read("Connection: Upgrade\x0d\x0a");
ok $atom->read("Host: example.com\x0d\x0a");
ok $atom->read("Origin: http://example.com\x0d\x0a");
ok $atom->read(
    "Sec-WebSocket-Key1: 18x 6]8vM;54 *(5:  {   U1]8  z [  8\x0d\x0a");
ok $atom->read(
    "Sec-WebSocket-Key2: 1_ tx7X d  <  nw  334J702) 7]o}` 0\x0d\x0a");
ok $atom->read("\x0d\x0aTm[K T2u");
ok !$s->error;

is $atom->buffer => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Sec-WebSocket-Origin: http://example.com\x0d\x0a"
  . "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a"
  . "\x0d\x0a"
  . "fQJ,fN/4F4!~K~MH";

$atom->bytes_written(length $atom->buffer);

is $handshake => 1;

my $message = 0;
$s->on_message(sub { $message++ });
ok $atom->read("\x00foo\xff");
is $message => 1;

$s->send_message('foo');
is $atom->buffer => "\x00foo\xff";
