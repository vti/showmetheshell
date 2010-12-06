#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 12;

use_ok 'Protocol::WebSocket::Response';

my $res;
my $message;

$res = Protocol::WebSocket::Response->new;
$res->version(75);
$res->host('example.com');
is $res->to_string => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "WebSocket-Origin: http://example.com\x0d\x0a"
  . "WebSocket-Location: ws://example.com/\x0d\x0a"
  . "\x0d\x0a";

$res = Protocol::WebSocket::Response->new;
$res->version(75);
$res->host('example.com');
$res->subprotocol('sample');
is $res->to_string => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "WebSocket-Protocol: sample\x0d\x0a"
  . "WebSocket-Origin: http://example.com\x0d\x0a"
  . "WebSocket-Location: ws://example.com/\x0d\x0a"
  . "\x0d\x0a";

$res = Protocol::WebSocket::Response->new;
$res->version(75);
$res->host('example.com');
$res->secure(1);
is $res->to_string => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "WebSocket-Origin: http://example.com\x0d\x0a"
  . "WebSocket-Location: wss://example.com/\x0d\x0a"
  . "\x0d\x0a";

$res = Protocol::WebSocket::Response->new;
$res->version(75);
$res->host('example.com');
$res->resource_name('/demo');
$res->origin('file://');
$res->cookie(name => 'foo', value => 'bar', path => '/');

is $res->to_string => "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "WebSocket-Origin: file://\x0d\x0a"
  . "WebSocket-Location: ws://example.com/demo\x0d\x0a"
  . "Set-Cookie: foo=bar; Path=/; Version=1\x0d\x0a"
  . "\x0d\x0a";


$res = Protocol::WebSocket::Response->new;
$res->parse("HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a");
$res->parse("Upgrade: WebSocket\x0d\x0a");
$res->parse("Connection: Upgrade\x0d\x0a");
$res->parse("WebSocket-Protocol: sample\x0d\x0a");
$res->parse("WebSocket-Origin: file://\x0d\x0a");
$res->parse("WebSocket-Location: ws://example.com/demo\x0d\x0a");
$res->parse("\x0d\x0a\x00foo\xff");
ok $res->is_done;
is $res->version     => 75;
is $res->subprotocol => 'sample';

$message =
    "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "WebSocket-Origin: file://\x0d\x0a"
  . "WebSocket-Location: ws://example.com/demo\x0d\x0a"
  . "\x0d\x0a\x00foo\xff";
$res = Protocol::WebSocket::Response->new;
ok $res->parse($message);
ok $res->is_done;
is $res->version => 75;
is $message      => "\x00foo\xff";
