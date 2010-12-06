#!/usr/bin/env perl

use strict;
use warnings;

use EventReactor;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

EventReactor->new(
    address   => 'localhost',
    port      => 3000,
    on_accept => sub {
        my ($self, $client) = @_;

        my $hs = Protocol::WebSocket::Handshake::Server->new;
        my $frame = Protocol::WebSocket::Frame->new;

        $client->on_read(
            sub {
                my ($client, $chunk) = @_;

                if (!$hs->is_done) {
                    $hs->parse($chunk);

                    if ($hs->is_done) {
                        $client->write($hs->to_string);
                    }

                    return;
                }

                $frame->append($chunk);

                while (my $message = $frame->next) {
                    $client->write($frame->new($message)->to_string);
                }
            }
        );
    }
)->listen->start;
