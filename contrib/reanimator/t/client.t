#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator::Client';

use Digest::MD5 'md5';
use EventReactor::ConnectedAtom;

my $handshake;

my $atom = EventReactor::ConnectedAtom->new;
my $s = ReAnimator::Client->new(
    url          => 'ws://example.com:3000/demo',
    atom         => $atom,
    on_handshake => sub { $handshake++ }
);

$atom->connected;
$atom->bytes_written(length $atom->buffer);

$atom->read("HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a");
$atom->read("Upgrade: WebSocket\x0d\x0a");
$atom->read("Connection: Upgrade\x0d\x0a");
$atom->read("Sec-WebSocket-Origin: file://\x0d\x0a");
$atom->read("Sec-WebSocket-Location: ws://example.com:3000/demo\x0d\x0a");
$atom->read("\x0d\x0a");
$atom->read(
    md5(    pack('N' => $s->handshake->req->number1)
          . pack('N' => $s->handshake->req->number2)
          . $s->handshake->req->challenge
    )
);

is $handshake => 1;

my $message = 0;
$s->on_message(sub { $message++ });
ok $atom->read("\x00foo\xff");
is $message => 1;

$s->send_message('foo');
is $atom->buffer => "\x00foo\xff";
