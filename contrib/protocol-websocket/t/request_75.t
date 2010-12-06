#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 82;

use_ok 'Protocol::WebSocket::Request';

my $req = Protocol::WebSocket::Request->new;
my $message;

$req = Protocol::WebSocket::Request->new;
ok !$req->is_done;
ok $req->parse;
ok $req->parse('');
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
is $req->state => 'fields';

ok $req->parse("Upgrade: WebSocket\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("Connection: Upgrade\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("Host: example.com\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("Origin: http://example.com\x0d\x0a");
is $req->state => 'fields';
ok $req->parse("\x0d\x0a");
is $req->state => 'done';

is $req->version       => 75;
is $req->resource_name => '/demo';
is $req->host          => 'example.com';
is $req->origin        => 'http://example.com';

$req = Protocol::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Upgrade\x0d\x0a");
ok $req->parse("Host: example.com:3000\x0d\x0a");
ok $req->parse("Origin: null\x0d\x0a");
ok $req->parse("\x0d\x0a");
is $req->version => 75;
is $req->state   => 'done';

$req = Protocol::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("UPGRADE: WebSocket\x0d\x0a");
ok $req->parse("CONNECTION: Upgrade\x0d\x0a");
ok $req->parse("HOST: example.com:3000\x0d\x0a");
ok $req->parse("ORIGIN: null\x0d\x0a");
ok $req->parse("\x0d\x0a");
is $req->version => 75;
is $req->state   => 'done';

$req = Protocol::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Upgrade\x0d\x0a");
ok $req->parse("Host: example.com:3000\x0d\x0a");
ok $req->parse("Origin: null\x0d\x0a");
ok $req->parse("WebSocket-Protocol: sample\x0d\x0a");
ok $req->parse("\x0d\x0a");
is $req->version     => 75;
is $req->state       => 'done';
is $req->subprotocol => 'sample';

$req = Protocol::WebSocket::Request->new;
$message =
    "GET /demo HTTP/1.1\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a";
ok $req->parse($message);
is $message => '';
$message =
  "Host: example.com:3000\x0d\x0a" . "Origin: null\x0d\x0a" . "\x0d\x0a";
ok $req->parse($message);
is $message      => '';
is $req->version => 75;
ok $req->is_done;

$req = Protocol::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Upgrade\x0d\x0a");
ok $req->parse("Host: example.com\x0d\x0a");
ok $req->parse("Origin: null\x0d\x0a");
ok $req->parse("Cookie: \$Version=1; foo=bar; \$Path=/\x0d\x0a");
ok $req->parse("\x0d\x0a");
ok $req->is_done;

is $req->cookies->[0]->version => 1;
is $req->cookies->[0]->name    => 'foo';
is $req->cookies->[0]->value   => 'bar';

$req = Protocol::WebSocket::Request->new(
    version       => 75,
    host          => 'example.com',
    resource_name => '/demo'
);
is $req->to_string => "GET /demo HTTP/1.1\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Host: example.com\x0d\x0a"
  . "Origin: http://example.com\x0d\x0a"
  . "\x0d\x0a";

$req = Protocol::WebSocket::Request->new(
    version       => 75,
    host          => 'example.com',
    subprotocol => 'sample',
    resource_name => '/demo'
);
is $req->to_string => "GET /demo HTTP/1.1\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Host: example.com\x0d\x0a"
  . "Origin: http://example.com\x0d\x0a"
  . "WebSocket-Protocol: sample\x0d\x0a"
  . "\x0d\x0a";

$req = Protocol::WebSocket::Request->new(
    version       => 75,
    host          => 'example.com',
    resource_name => '/demo'
);
is $req->to_string => "GET /demo HTTP/1.1\x0d\x0a"
  . "Upgrade: WebSocket\x0d\x0a"
  . "Connection: Upgrade\x0d\x0a"
  . "Host: example.com\x0d\x0a"
  . "Origin: http://example.com\x0d\x0a"
  . "\x0d\x0a";

$req = Protocol::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Bar\x0d\x0a");
ok $req->parse("Host: example.com\x0d\x0a");
ok $req->parse("Origin: http://example.com\x0d\x0a");
ok not defined $req->parse("\x0d\x0a");
ok $req->is_state('error');
is $req->error => 'Not a valid request';

$req = Protocol::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Upgrade\x0d\x0a");
ok $req->parse("Host: example.com\x0d\x0a");
ok $req->parse("Origin: http://example.com\x0d\x0a");
ok not defined $req->parse("\x0d\x0afoo");
ok $req->is_state('error');
is $req->error => 'Leftovers';
