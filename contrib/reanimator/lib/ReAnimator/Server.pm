package ReAnimator::Server;

use strict;
use warnings;

use base 'ReAnimator::AtomDecorator';

use Protocol::WebSocket::Handshake::Server;

sub new {
    my $self = shift->SUPER::new(@_);

    my $atom = $self->atom;
    $atom->on_read(sub { $self->parse($_[1]) });

    $self->{on_request} ||= sub { };

    return $self;
}

sub on_request {
    @_ > 1 ? $_[0]->{on_request} = $_[1] : $_[0]->{on_request};
}

sub parse {
    my $self  = shift;
    my $chunk = shift;

    my $handshake = $self->handshake;

    unless ($handshake->is_done) {
        unless ($handshake->parse($chunk)) {
            $self->error($handshake->error);
            return;
        }

        if ($handshake->is_done) {
            $self->on_request->($self, $self->handshake);

            $self->write(
                $handshake->to_string => sub {
                    my $atom = shift;

                    $self->on_handshake->($self);
                }
            );
        }

        return 1;
    }

    $self->_parse_frames($chunk);

    return 1;
}

sub send_message {
    my $self    = shift;
    my $message = shift;

    my $req = $self->handshake->req;
    unless ($req->is_done) {
        Carp::carp qq/Can't send_message, handshake is not done yet./;
        return;
    }

    $self->SUPER::send_message($message);
}

sub _build_handshake { shift; Protocol::WebSocket::Handshake::Server->new(@_) }

1;
