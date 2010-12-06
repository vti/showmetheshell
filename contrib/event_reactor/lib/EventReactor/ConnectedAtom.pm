package EventReactor::ConnectedAtom;

use strict;
use warnings;

use base 'EventReactor::Atom';

use constant DEBUG => $ENV{EVENT_REACTOR_DEBUG} ? 1 : 0;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{on_connect}
      ||= sub { warn 'Unhandled on_connect event' if DEBUG };

    $self->state('connecting');

    return $self;
}

sub on_connect { @_ > 1 ? $_[0]->{on_connect} = $_[1] : $_[0]->{on_connect} }

sub connecting    { shift->state('connecting') }
sub is_connecting { shift->is_state('connecting') }

sub connected {
    my $self = shift;

    $self->state('connected');

    $self->on_connect->($self);

    return $self;
}

sub is_connected { shift->handle->connected }

1;
