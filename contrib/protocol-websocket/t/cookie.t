#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 29;

use_ok 'Protocol::WebSocket::Cookie';
use_ok 'Protocol::WebSocket::Cookie::Response';
use_ok 'Protocol::WebSocket::Cookie::Request';

my $cookie;
my $cookies;

$cookie = Protocol::WebSocket::Cookie->new;
$cookie->parse;
$cookie->parse('');
$cookie->parse('foo=bar; baz = zab; hello= "the;re"; here');
is_deeply($cookie->pairs,
    [[foo => 'bar'], [baz => 'zab'], [hello => 'the;re'], ['here', undef]]);
is $cookie->to_string => 'foo=bar; baz=zab; hello="the;re"; here';

$cookie = Protocol::WebSocket::Cookie->new;
$cookie->parse('$Foo="bar"');
is_deeply($cookie->pairs, [['$Foo' => 'bar']]);

$cookie = Protocol::WebSocket::Cookie->new;
$cookie->parse('foo=bar=123=xyz');
is_deeply($cookie->pairs, [['foo' => 'bar=123=xyz']]);

$cookie =
  Protocol::WebSocket::Cookie::Response->new(name => 'foo', value => 'bar');
is $cookie->to_string => 'foo=bar; Version=1';
$cookie = Protocol::WebSocket::Cookie::Response->new(
    name    => 'foo',
    value   => 'bar',
    discard => 1,
    max_age => 0
);
is $cookie->to_string => 'foo=bar; Discard; Max-Age=0; Version=1';

$cookie = Protocol::WebSocket::Cookie::Response->new(
    name     => 'foo',
    value    => 'bar',
    portlist => 80
);
is $cookie->to_string => 'foo=bar; Port="80"; Version=1';

$cookie = Protocol::WebSocket::Cookie::Response->new(
    name     => 'foo',
    value    => 'bar',
    portlist => [80, 443]
);
is $cookie->to_string => 'foo=bar; Port="80 443"; Version=1';

$cookie = Protocol::WebSocket::Cookie::Request->new;
$cookies = $cookie->parse('$Version=1; foo=bar; $Path=/; $Domain=.example.com');
is $cookies->[0]->name    => 'foo';
is $cookies->[0]->value   => 'bar';
is $cookies->[0]->version => 1;
is $cookies->[0]->path    => '/';
is $cookies->[0]->domain  => '.example.com';

$cookie = Protocol::WebSocket::Cookie::Request->new;
$cookies = $cookie->parse('$Version=1; foo=bar');
is $cookies->[0]->name    => 'foo';
is $cookies->[0]->value   => 'bar';
is $cookies->[0]->version => 1;
ok not defined $cookies->[0]->path;
ok not defined $cookies->[0]->domain;

$cookie = Protocol::WebSocket::Cookie::Request->new;
$cookies = $cookie->parse('$Version=1; foo="hello\"there"');
is $cookies->[0]->name  => 'foo';
is $cookies->[0]->value => 'hello"there';

$cookie = Protocol::WebSocket::Cookie::Request->new;
$cookies = $cookie->parse(
    '$Version=1; foo="bar"; $Path=/; bar=baz; $Domain=.example.com');
is $cookies->[0]->name   => 'foo';
is $cookies->[0]->value  => 'bar';
is $cookies->[0]->path   => '/';
is $cookies->[1]->name   => 'bar';
is $cookies->[1]->value  => 'baz';
is $cookies->[1]->domain => '.example.com';
