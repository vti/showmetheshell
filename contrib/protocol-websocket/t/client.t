#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 14;

use_ok 'Protocol::WebSocket::Handshake::Client';

my $h = Protocol::WebSocket::Handshake::Client->new;
$h->url('ws://example.com/demo');

# Mocking
$h->req->key1("18x 6]8vM;54 *(5:  {   U1]8  z [  8");
$h->req->key2("1_ tx7X d  <  nw  334J702) 7]o}` 0");
$h->req->challenge("Tm[K T2u");

is $h->to_string => "GET /demo HTTP/1.1\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Host: example.com\x0d\x0a"
  . "Origin: http://example.com\x0d\x0a"
  . "Sec-WebSocket-Key1: 18x 6]8vM;54 *(5:  {   U1]8  z [  8\x0d\x0a"
  . "Sec-WebSocket-Key2: 1_ tx7X d  <  nw  334J702) 7]o}` 0\x0d\x0a"
  . "Content-Length: 8\x0d\x0a"
  . "\x0d\x0aTm[K T2u";

$h = Protocol::WebSocket::Handshake::Client->new(url => 'ws://example.com');

# Mocking
$h->req->key1("18x 6]8vM;54 *(5:  {   U1]8  z [  8");
$h->req->key2("1_ tx7X d  <  nw  334J702) 7]o}` 0");
$h->req->challenge("Tm[K T2u");

is $h->to_string => "GET / HTTP/1.1\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Host: example.com\x0d\x0a"
  . "Origin: http://example.com\x0d\x0a"
  . "Sec-WebSocket-Key1: 18x 6]8vM;54 *(5:  {   U1]8  z [  8\x0d\x0a"
  . "Sec-WebSocket-Key2: 1_ tx7X d  <  nw  334J702) 7]o}` 0\x0d\x0a"
  . "Content-Length: 8\x0d\x0a"
  . "\x0d\x0aTm[K T2u";

ok !$h->is_done;
ok $h->parse;
ok $h->parse('');

ok $h->parse("HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
      . "Upgrade: WebSocket\x0d\x0a"
      . "Connection: Upgrade\x0d\x0a"
      . "Sec-WebSocket-Origin: http://example.com\x0d\x0a"
      . "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a"
      . "\x0d\x0a"
      . "fQJ,fN/4F4!~K~MH");
ok !$h->error;
ok $h->is_done;

my $message = "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a";
$h = Protocol::WebSocket::Handshake::Client->new(url => 'ws://example.com');
ok $h->parse($message);
is $message => '';
ok !$h->error;

$h = Protocol::WebSocket::Handshake::Client->new;
ok !$h->parse("HTTP/1.0 foo bar\x0d\x0a");
is $h->error => 'Wrong response line';
