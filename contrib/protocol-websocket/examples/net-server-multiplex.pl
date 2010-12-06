#!/usr/bin/env perl

package SampleChatServer;

use strict;
use warnings;

use base 'Net::Server::Multiplex';

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

__PACKAGE__->run;

my $hs;
my $frame;

sub mux_connection {
    my $self = shift;
    my ($mux, $fh) = @_;
    my $peer = $self->{peeraddr};

    $self->{id}       = $self->{net_server}->{server}->{requests};
    $self->{peerport} = $self->{net_server}->{server}->{peerport};
}

sub mux_input {
    my $self = shift;
    my ($mux, $fh, $in_ref) = @_;

    $hs    ||= Protocol::WebSocket::Handshake::Server->new;
    $frame ||= Protocol::WebSocket::Frame->new;

    if (!$hs->is_done) {
        $hs->parse($$in_ref);

        if ($hs->is_done) {
            print $fh $hs->to_string;
        }

        $$in_ref = "";
        return 0;
    }

    $frame->append($$in_ref);

    while (my $message = $frame->next) {
        print $fh $frame->new($message)->to_string;
    }

    $$in_ref = "";
}
