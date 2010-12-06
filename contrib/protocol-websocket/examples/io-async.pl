#!/usr/bin/env perl

use strict;
use warnings;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

use IO::Socket::INET;
use IO::Async::Listener;

use IO::Async::Loop;
my $loop = IO::Async::Loop->new;

my $listener = IO::Async::Listener->new(
    on_stream => sub {
        my ($self, $stream) = @_;

        my $hs    = Protocol::WebSocket::Handshake::Server->new;
        my $frame = Protocol::WebSocket::Frame->new;

        $stream->configure(
            on_read => sub {
                my ($self, $buffref, $closed) = @_;

                if (!$hs->is_done) {
                    $hs->parse($$buffref);

                    if ($hs->is_done) {
                        $self->write($hs->to_string);
                    }

                    $$buffref = "";
                    return 0;
                }

                $frame->append($$buffref);

                while (my $message = $frame->next) {
                    $self->write($frame->new($message)->to_string);
                }

                $$buffref = "";
                return 0;
            }
        );

        $loop->add($stream);
    }
);

$loop->add($listener);

my $socket = IO::Socket::INET->new(
    LocalAddr => 'localhost',
    LocalPort => 3000,
    Listen    => 1,
);

$listener->listen(handle => $socket);
#$listener->listen(addr => ['localhost'], port => 3000, on_listen_error => sub {});

$loop->loop_forever;
