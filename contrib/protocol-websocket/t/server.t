#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 20;

use_ok 'Protocol::WebSocket::Handshake::Server';

my $h = Protocol::WebSocket::Handshake::Server->new;

ok !$h->is_done;
ok $h->parse;
ok $h->parse('');

ok $h->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $h->parse("Upgrade: WebSocket\x0d\x0a");
ok $h->parse("Connection: Upgrade\x0d\x0a");
ok $h->parse("Host: example.com\x0d\x0a");
ok $h->parse("Origin: http://example.com\x0d\x0a");
ok $h->parse(
    "Sec-WebSocket-Key1: 18x 6]8vM;54 *(5:  {   U1]8  z [  8\x0d\x0a");
ok $h->parse(
    "Sec-WebSocket-Key2: 1_ tx7X d  <  nw  334J702) 7]o}` 0\x0d\x0a");
ok $h->parse("\x0d\x0aTm[K T2u");
ok !$h->error;
ok $h->is_done;

is $h->to_string => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Sec-WebSocket-Origin: http://example.com\x0d\x0a"
  . "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a"
  . "\x0d\x0a"
  . "fQJ,fN/4F4!~K~MH";

my $message = "GET /demo HTTP/1.1\x0d\x0a";
$h = Protocol::WebSocket::Handshake::Server->new;
ok $h->parse($message);
is $message => '';
ok !$h->error;

$h = Protocol::WebSocket::Handshake::Server->new;
ok !$h->parse("GET /demo\x0d\x0a");
is $h->error => 'Wrong request line';
