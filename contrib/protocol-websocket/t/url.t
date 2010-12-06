#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 25;

use_ok 'Protocol::WebSocket::URL';

my $url = Protocol::WebSocket::URL->new;
ok $url->parse('ws://example.com');
ok !$url->secure;
is $url->host          => 'example.com';
is $url->resource_name => '/';

$url = Protocol::WebSocket::URL->new;
ok $url->parse('ws://example.com/');
ok !$url->secure;
is $url->host          => 'example.com';
is $url->resource_name => '/';

$url = Protocol::WebSocket::URL->new;
ok $url->parse('ws://example.com/demo');
ok !$url->secure;
is $url->host          => 'example.com';
is $url->resource_name => '/demo';

$url = Protocol::WebSocket::URL->new;
ok $url->parse('ws://example.com:3000');
ok !$url->secure;
is $url->host          => 'example.com';
is $url->port          => '3000';
is $url->resource_name => '/';

$url = Protocol::WebSocket::URL->new;
ok $url->parse('ws://example.com/demo?foo=bar');
ok !$url->secure;
is $url->host          => 'example.com';
is $url->resource_name => '/demo';

$url = Protocol::WebSocket::URL->new(host => 'foo.com', secure => 1);
is $url->to_string => 'wss://foo.com/';

$url = Protocol::WebSocket::URL->new(
    host          => 'foo.com',
    resource_name => '/demo'
);
is $url->to_string => 'ws://foo.com/demo';

$url = Protocol::WebSocket::URL->new(
    host => 'foo.com',
    port => 3000
);
is $url->to_string => 'ws://foo.com:3000/';
