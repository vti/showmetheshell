package EventReactor::Timer;

use strict;
use warnings;

use Time::HiRes 'time';

require Carp;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    my $self = {@_};
    bless $self, $class;

    $self->{set_time} = time;
    $self->{called}   = 0;

    Carp::croak qq/Interval is required/ unless $self->{interval};

    return $self;
}

sub one_shot { @_ > 1 ? $_[0]->{one_shot} = $_[1] : $_[0]->{one_shot} }
sub interval { @_ > 1 ? $_[0]->{interval} = $_[1] : $_[0]->{interval} }
sub set_time { @_ > 1 ? $_[0]->{set_time} = $_[1] : $_[0]->{set_time} }

sub called { shift->{called} }
sub cb     { shift->{cb} }

sub wake_up {
    my $self = shift;

    return 0 if $self->called && $self->one_shot;

    if (time - $self->set_time >= $self->interval) {
        $self->set_time(time);
        $self->call;
        return 1;
    }

    return 0;
}

sub call {
    my $self = shift;

    $self->{called}++;

    $self->cb->();
}

1;
