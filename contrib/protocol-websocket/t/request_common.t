#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 14;

use_ok 'Protocol::WebSocket::Request';

my $req = Protocol::WebSocket::Request->new;

$req = Protocol::WebSocket::Request->new;
ok !$req->is_done;
ok not defined $req->parse("foo\x0d\x0a");
ok $req->is_state('error');
is $req->error => 'Wrong request line';

$req = Protocol::WebSocket::Request->new;
ok $req->parse("GET /demo HTTP/1.1\x0d\x0a");
ok $req->parse("Upgrade: WebSocket\x0d\x0a");
ok $req->parse("Connection: Upgrade\x0d\x0a");
ok $req->parse("Origin: http://example.com\x0d\x0a");
ok not defined $req->parse("\x0d\x0a");
ok $req->is_state('error');

$req = Protocol::WebSocket::Request->new;
ok not defined $req->parse('x' x (1024 * 10));
ok $req->is_state('error');
is $req->error => 'Message is too long';
