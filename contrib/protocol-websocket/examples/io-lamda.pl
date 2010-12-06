#!/usr/bin/env perl

use strict;
use warnings;

use IO::Socket;
use IO::Lambda qw(:all);
use IO::Lambda::Socket qw(:all);

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

my $conn_timeout = 10;

my $server = IO::Socket::INET->new(
    Listen    => 5,
    LocalPort => 3000,
    Blocking  => 0,
    ReuseAddr => 1,
) or die $!;

my $serv = lambda {
    context $server;
    accept {
        my $conn = shift;

        again;

        $conn->blocking(0);

        my $hs    = Protocol::WebSocket::Handshake::Server->new;
        my $frame = Protocol::WebSocket::Frame->new;

        my $buf = '';
        context readbuf, $conn, \$buf, qr/^(.*)$/s, $conn_timeout;

    tail {
        my ($match, $error) = @_;

        return close($conn) unless defined $match;

        substr($buf, 0, length($match)) = '';

        my $res = '';
        if (!$hs->is_done) {
            $hs->parse($match);

            if ($hs->is_done) {
                $res = $hs->to_string;
            }

            $match = '';
        }

        $frame->append($match);

        while (my $message = $frame->next) {
            $res .= $frame->new($message)->to_string;
        }

        again;

        $match = '';
        context writebuf, $conn, \$res, length($res), 0, $conn_timeout;
        &tail();
    }}
};

$serv->wait;
