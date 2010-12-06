#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent::Impl::Perl;
use AE;
use AnyEvent::HTTP::Server;

AnyEvent::HTTP::Server->new(
    host    => '0.0.0.0',
    port    => 3000,
    pid     => '/tmp/wsecho.pid',
    request => sub {
        my $r = shift;

        $r->upgrade(
            websocket => sub {
                my $ws = shift;

                $ws->onmessage(sub { $ws->send(@_) });
            }
        );

        return 1;
    }
)->start;

AE::cv->recv;
