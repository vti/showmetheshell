#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent::Socket;
use AnyEvent::Handle;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

my $cv = AnyEvent->condvar;

my $hdl;

AnyEvent::Socket::tcp_server undef, 3000, sub {
    my ($clsock, $host, $port) = @_;

    my $hs    = Protocol::WebSocket::Handshake::Server->new;
    my $frame = Protocol::WebSocket::Frame->new;

    $hdl = AnyEvent::Handle->new(fh => $clsock);

    $hdl->on_read(
        sub {
            my $hdl = shift;

            my $chunk = $hdl->{rbuf};
            $hdl->{rbuf} = undef;

            if (!$hs->is_done) {
                $hs->parse($chunk);

                if ($hs->is_done) {
                    $hdl->push_write($hs->to_string);
                    return;
                }
            }

            $frame->append($chunk);

            while (my $message = $frame->next) {
                $hdl->push_write($frame->new($message)->to_string);
            }
        }
    );
};

$cv->wait;
