package ReAnimator::AtomDecorator;

use strict;
use warnings;

use Protocol::WebSocket::Frame;

require Carp;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    my $atom = $self->atom;
    Carp::croak qq/Something went wrong during atom decoration/ unless $atom;

    $self->{frame} = $self->_build_frame;
    $self->{handshake} = $self->_build_handshake(secure => $atom->secure);

    $self->{on_message}   ||= sub { };
    $self->{on_handshake} ||= sub { };

    return $self;
}

sub atom  { shift->{atom} }
sub frame { shift->{frame} }

sub handshake { @_ > 1 ? $_[0]->{handshake} = $_[1] : $_[0]->{handshake} }

sub on_message { @_ > 1 ? $_[0]->{on_message} = $_[1] : $_[0]->{on_message} }

sub on_handshake {
    @_ > 1 ? $_[0]->{on_handshake} = $_[1] : $_[0]->{on_handshake};
}

sub handle { shift->atom->handle }
sub error  { shift->atom->error(@_) }
sub write  { shift->atom->write(@_) }

sub connected    { shift->atom->connected }
sub disconnected { shift->atom->disconnected }

sub send_message {
    my ($self, $message) = @_;

    my $frame = Protocol::WebSocket::Frame->new($message);
    $self->write($frame->to_string);
}

sub _build_frame { shift; Protocol::WebSocket::Frame->new(@_) }

sub _parse_frames {
    my ($self, $chunk) = @_;

    my $frame = $self->frame;
    $frame->append($chunk);

    while (my $message = $frame->next) {
        $self->on_message->($self, $message);
    }
}

1;
