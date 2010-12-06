#!/usr/bin/env perl

use strict;
use warnings;

use IO::Event;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

my $ioe = IO::Event::Socket::INET->new(
    LocalAddr => 'localhost',
    LocalPort => 3000,
    Listen    => 1,
    Blocking  => 0
);

IO::Event::loop;

my $hs;
my $frame;

sub ie_connection {
    my ($handler, $ioe) = @_;

    $hs    = Protocol::WebSocket::Handshake::Server->new;
    $frame = Protocol::WebSocket::Frame->new;

    $ioe->accept;
}

sub ie_input {
    my ($handler, $client, $input_buffer_reference) = @_;

    if (!$hs->is_done) {
        $hs->parse($$input_buffer_reference);

        if ($hs->is_done) {
            print $client $hs->to_string;
        }

        $$input_buffer_reference = '';
        return;
    }

    $frame->append($$input_buffer_reference);

    while (my $message = $frame->next) {
        print $client $frame->new($message)->to_string;
    }

    $$input_buffer_reference = '';
    return;
}
