#!/usr/bin/env perl

use strict;
use warnings;

use IO::Socket;
use IO::Multiplex;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

my $mux = new IO::Multiplex;

my $sock = new IO::Socket::INET(
    Proto     => 'tcp',
    LocalPort => 3000,
    Listen    => 1
) or die "socket: $@";

$mux->listen($sock);

$mux->set_callback_object(__PACKAGE__);
$mux->loop;

my $hs;
my $frame;

sub mux_input {
    my $package = shift;
    my $mux     = shift;
    my $fh      = shift;
    my $input   = shift;

    $hs    ||= Protocol::WebSocket::Handshake::Server->new;
    $frame ||= Protocol::WebSocket::Frame->new;

    foreach my $c ($mux->handles) {
        if (!$hs->is_done) {
            $hs->parse($$input);

            if ($hs->is_done) {
                print $c $hs->to_string;
            }

            $$input = '';
            return;
        }

        $frame->append($$input);

        while (my $message = $frame->next) {
            print $c $frame->new($message)->to_string;
        }
    }

    $$input = '';
}
