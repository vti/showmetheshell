#!/usr/bin/env perl

use strict;
use warnings;

BEGIN { use FindBin; use lib "$FindBin::Bin/../lib" }

use IO::Socket::INET;
use IO::Poll qw/POLLIN POLLOUT/;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

my $poll = IO::Poll->new;

my $socket = IO::Socket::INET->new(
    Blocking  => 0,
    LocalAddr => 'localhost',
    LocalPort => 3000,
    Proto     => 'tcp',
    Type      => SOCK_STREAM,
    Listen    => 1
);

$socket->blocking(0);

$socket->listen;

my $client;

while (1) {
    if ($client = $socket->accept) {
        $poll->mask($client => POLLIN | POLLOUT);
        last;
    }
}

my $hs    = Protocol::WebSocket::Handshake::Server->new;
my $frame = Protocol::WebSocket::Frame->new;

my $buffer = '';

LOOP: while (1) {
    $poll->poll(0.1);

    foreach my $reader ($poll->handles(POLLIN)) {
        my $rs = $client->sysread(my $chunk, 1024);
        last LOOP unless $rs;

        if (!$hs->is_done) {
            unless (defined $hs->parse($chunk)) {
                warn "Error: " . $hs->error;
                last LOOP;
            }

            if ($hs->is_done) {
                $buffer .= $hs->to_string;
            }

            next;
        }

        $frame->append($chunk);

        while (defined(my $message = $frame->next)) {
            $buffer .= $frame->new($message)->to_string;
        }
    }

    foreach my $writer ($poll->handles(POLLOUT)) {
        next unless length $buffer;

        my $rs = $writer->syswrite($buffer);
        substr $buffer, 0, $rs, '';
    }
}
