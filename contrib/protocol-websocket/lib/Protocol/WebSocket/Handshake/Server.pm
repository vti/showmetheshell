package Protocol::WebSocket::Handshake::Server;

use strict;
use warnings;

use base 'Protocol::WebSocket::Handshake';

sub parse {
    my $self  = shift;

    my $req = $self->req;
    my $res = $self->res;

    unless ($req->is_done) {
        unless ($req->parse($_[0])) {
            $self->error($req->error);
            return;
        }

        if ($req->is_done) {
            $res->version($req->version);
            $res->host($req->host);

            #$res->secure($req->secure);
            $res->resource_name($req->resource_name);
            $res->origin($req->origin);

            if ($req->version > 75) {
                $res->number1($req->number1);
                $res->number2($req->number2);
                $res->challenge($req->challenge);
            }
        }
    }

    return 1;
}

sub is_done   { shift->req->is_done }
sub to_string { shift->res->to_string }

1;
__END__

=head1 NAME

Protocol::WebSocket::Handshake::Server - WebSocket Server Handshake

=head1 SYNOPSIS

    my $h = Protocol::WebSocket::Handshake::Server->new;

    # Parse client request
    $h->parse(<<"EOF");
    GET /demo HTTP/1.1
    Upgrade: WebSocket
    Connection: Upgrade
    Host: example.com
    Origin: http://example.com
    Sec-WebSocket-Key1: 18x 6]8vM;54 *(5:  {   U1]8  z [  8
    Sec-WebSocket-Key2: 1_ tx7X d  <  nw  334J702) 7]o}` 0

    Tm[K T2u
    EOF

    $h->error;   # Check if there were any errors
    $h->is_done; # Returns 1

    # Create response
    $h->to_string; # HTTP/1.1 101 WebSocket Protocol Handshake
                   # Upgrade: WebSocket
                   # Connection: Upgrade
                   # Sec-WebSocket-Origin: http://example.com
                   # Sec-WebSocket-Location: ws://example.com/demo
                   #
                   # fQJ,fN/4F4!~K~MH

=head1 DESCRIPTION

Construct or parse a server WebSocket handshake. This module is written for
convenience, since using request and response directly requires the same code
again and again.

=head1 ATTRIBUTES

=head1 METHODS

=head2 C<new>

Create a new L<Protocol::WebSocket::Handshake::Server> instance.

=head2 C<parse>

    $handshake->parse($buffer);

Parse a WebSocket client request. Returns C<undef> and sets C<error> attribute
on error. Buffer is modified.

=head2 C<to_string>

Construct a WebSocket server response.

=head2 C<is_done>

Check whether handshake is done.

=cut
