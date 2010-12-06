package EventReactor::Atom;

use strict;
use warnings;

use base 'EventReactor::Stateful';

use constant DEBUG => $ENV{EVENT_REACTOR_DEBUG} ? 1 : 0;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{on_disconnect} ||= sub {
        warn 'Unhandled on_disconnect event'
          if DEBUG;
    };

    $self->{on_read}  ||= sub { warn 'Unhandled on_read event'  if DEBUG };
    $self->{on_write} ||= sub { warn 'Unhandled on_write event' if DEBUG };
    $self->{on_error} ||= sub { warn 'Unhandled on_error event' if DEBUG };

    $self->{chunks} = [];
    $self->{buffer} = '';

    $self->state('accepting');

    return $self;
}

sub is_accepting  {0}
sub is_connecting {0}

sub handle { @_ > 1 ? $_[0]->{handle} = $_[1] : $_[0]->{handle} }
sub secure { @_ > 1 ? $_[0]->{secure} = $_[1] : $_[0]->{secure} }

sub on_disconnect {
    @_ > 1 ? $_[0]->{on_disconnect} = $_[1] : $_[0]->{on_disconnect};
}
sub on_read  { @_ > 1 ? $_[0]->{on_read}  = $_[1] : $_[0]->{on_read} }
sub on_error { @_ > 1 ? $_[0]->{on_error} = $_[1] : $_[0]->{on_error} }

sub on_write { @_ > 1 ? $_[0]->{on_write} = $_[1] : $_[0]->{on_write} }

sub error {
    my $self  = shift;
    my $error = shift;

    return $self->{error} unless defined $error;

    $self->{error} = $error;
    $self->on_error->($self, $error);

    return $self;
}

sub disconnected {
    my $self = shift;

    $self->state('disconnected');

    $self->on_disconnect->($self);

    return $self;
}

sub read {
    my $self  = shift;
    my $chunk = shift;

    $self->on_read->($self, $chunk);

    return 1;
}

sub write {
    my $self  = shift;
    my $chunk = shift;
    my $cb    = shift;

    push @{$self->{chunks}}, [$chunk => $cb];

    $self->{buffer} .= $chunk;
    $self->on_write->($self);
}

sub bytes_written {
    my $self  = shift;
    my $count = shift;

    substr $self->{buffer}, 0, $count, '';

    while (my $chunk = $self->{chunks}->[0]) {
        my $length = length $chunk->[0];

        if ($count >= $length) {
            shift @{$self->{chunks}};

            $count -= $length;

            $chunk->[1]->($self) if $chunk->[1];

            next if $count > 0;

            last;
        }

        substr $chunk->[0], 0, $count, '';
        last;
    }

    return $self;
}

sub is_writing {
    my $self = shift;

    return length $self->{buffer} ? 1 : 0;
}

sub buffer { shift->{buffer} }

1;
