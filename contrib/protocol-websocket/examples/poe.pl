#!/usr/bin/env perl

use warnings;
use strict;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

use POE qw(Component::Server::TCP);

my $hs    = Protocol::WebSocket::Handshake::Server->new;
my $frame = Protocol::WebSocket::Frame->new;

POE::Component::Server::TCP->new(
    Port         => 3000,
    ClientFilter => 'POE::Filter::Stream',
    ClientInput  => sub {
        my $chunk = $_[ARG0];

        if (!$hs->is_done) {
            $hs->parse($chunk);

            if ($hs->is_done) {
                $_[HEAP]{client}->put($hs->to_string);
            }

            return;
        }

        $frame->append($chunk);

        while (my $message = $frame->next) {
            $_[HEAP]{client}->put($frame->new($message)->to_string);
        }
    }
);

POE::Kernel->run;
