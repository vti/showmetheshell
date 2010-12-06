#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 33;

use_ok 'Protocol::WebSocket::Response';

my $res;

$res = Protocol::WebSocket::Response->new;
ok $res->parse("HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a");
ok $res->parse("Upgrade: WebSocket\x0d\x0a");
ok $res->parse("Connection: Upgrade\x0d\x0a");
ok $res->parse("Sec-WebSocket-Origin: file://\x0d\x0a");
ok $res->parse("Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a");
ok $res->parse("\x0d\x0a");
ok $res->parse("0st3Rl&q-2ZU^weu");
ok $res->is_done;
is $res->checksum => '0st3Rl&q-2ZU^weu';
ok !$res->secure;
is $res->host          => 'example.com';
is $res->resource_name => '/demo';
is $res->origin        => 'file://';

$res = Protocol::WebSocket::Response->new;
ok $res->parse("HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a");
ok $res->parse("Upgrade: WebSocket\x0d\x0a");
ok $res->parse("Connection: Upgrade\x0d\x0a");
ok $res->parse("Sec-WebSocket-Protocol: sample\x0d\x0a");
ok $res->parse("Sec-WebSocket-Origin: file://\x0d\x0a");
ok $res->parse("Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a");
ok $res->parse("\x0d\x0a");
ok $res->parse("0st3Rl&q-2ZU^weu");
ok $res->is_done;
is $res->subprotocol => 'sample';

$res = Protocol::WebSocket::Response->new;
my $message =
    "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a";
ok $res->parse($message);
is $message => '';
$message =
    "Sec-WebSocket-Origin: file://\x0d\x0a"
  . "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a"
  . "\x0d\x0a"
  . "0st3Rl&q-2ZU^weu\x00foo\xff";
ok $res->parse($message);
ok $res->is_done;
is $message => "\x00foo\xff";

$res = Protocol::WebSocket::Response->new(
    host          => 'example.com',
    resource_name => '/demo',
    origin        => 'file://',
    number1       => 777_007_543,
    number2       => 114_997_259,
    challenge     => "\x47\x30\x22\x2D\x5A\x3F\x47\x58"
);
is $res->to_string => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Sec-WebSocket-Origin: file://\x0d\x0a"
  . "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a"
  . "\x0d\x0a"
  . "0st3Rl&q-2ZU^weu";

$res = Protocol::WebSocket::Response->new(
    host          => 'example.com',
    resource_name => '/demo',
    origin        => 'file://',
    subprotocol   => 'sample',
    number1       => 777_007_543,
    number2       => 114_997_259,
    challenge     => "\x47\x30\x22\x2D\x5A\x3F\x47\x58"
);
is $res->to_string => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Sec-WebSocket-Protocol: sample\x0d\x0a"
  . "Sec-WebSocket-Origin: file://\x0d\x0a"
  . "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a"
  . "\x0d\x0a"
  . "0st3Rl&q-2ZU^weu";

$res = Protocol::WebSocket::Response->new(
    secure        => 1,
    host          => 'example.com',
    resource_name => '/demo',
    origin        => 'file://',
    number1       => 777_007_543,
    number2       => 114_997_259,
    challenge     => "\x47\x30\x22\x2D\x5A\x3F\x47\x58"
);
is $res->to_string => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Sec-WebSocket-Origin: file://\x0d\x0a"
  . "Sec-WebSocket-Location: wss://example.com/demo\x0d\x0a"
  . "\x0d\x0a"
  . "0st3Rl&q-2ZU^weu";

$res = Protocol::WebSocket::Response->new(
    host          => 'example.com',
    resource_name => '/demo',
    origin        => 'file://',
    key1          => "18x 6]8vM;54 *(5:  {   U1]8  z [  8",
    key2          => "1_ tx7X d  <  nw  334J702) 7]o}` 0",
    challenge     => "Tm[K T2u"
);
is $res->to_string => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Sec-WebSocket-Origin: file://\x0d\x0a"
  . "Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a"
  . "\x0d\x0a"
  . "fQJ,fN/4F4!~K~MH";
