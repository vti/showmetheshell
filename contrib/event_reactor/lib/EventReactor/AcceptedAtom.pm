package EventReactor::AcceptedAtom;

use strict;
use warnings;

use base 'EventReactor::Atom';

use constant DEBUG => $ENV{EVENT_REACTOR_DEBUG} ? 1 : 0;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{on_accept} ||= sub { warn 'Unhandled on_accept event' if DEBUG };

    $self->state('accepting');

    return $self;
}

sub on_accept { @_ > 1 ? $_[0]->{on_accept} = $_[1] : $_[0]->{on_accept} }

sub accepting    { shift->state('accepting') }
sub is_accepting { shift->is_state('accepting') }

sub accepted {
    my $self = shift;

    $self->state('accepted');

    $self->on_accept->($self);

    return $self;
}

sub is_accepted { shift->state('accepted') }

1;
