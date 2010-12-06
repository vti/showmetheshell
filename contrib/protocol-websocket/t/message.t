#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

use_ok 'Protocol::WebSocket::Message';

my $m;

$m = Protocol::WebSocket::Message->new;
ok $m->parse("HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a");
ok $m->parse("Upgrade: WebSocket\x0d\x0a");
ok $m->parse("Connection: Upgrade\x0d\x0a");
ok $m->parse("Sec-WebSocket-Origin: file://\x0d\x0a");
ok $m->parse("Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a");
ok $m->parse("\x0d\x0a0st\x0d\x0al&q-2ZU^weu");
ok $m->is_done;
