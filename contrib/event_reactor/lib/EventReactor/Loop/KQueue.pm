package EventReactor::Loop::KQueue;

use strict;
use warnings;

use IO::KQueue;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    my $self = {@_};
    bless $self, $class;

    $self->{kqueue} = IO::KQueue->new;

    $self->{kevent} = [];

    return $self;
}

sub kqueue { shift->{kqueue} }

sub tick {
    my $self    = shift;
    my $timeout = shift;

    # Interrupted system call
    eval { $self->{kevent} = [$self->kqueue->kevent($timeout * 1000)]; };
}

sub _set {
    shift->kqueue->EV_SET(fileno(shift), @_);
}

sub _events { @{$_[0]->{kevent}} }

sub mask_rw {
    $_[0]->_set($_[1], EVFILT_READ,  EV_ADD);
    $_[0]->_set($_[1], EVFILT_WRITE, EV_ADD);
}

sub mask_ro {
    $_[0]->_set($_[1], EVFILT_WRITE, EV_DELETE);
    $_[0]->_set($_[1], EVFILT_READ,  EV_ADD);
}

sub mask_wo {
    $_[0]->_set($_[1], EVFILT_READ,  EV_DELETE);
    $_[0]->_set($_[1], EVFILT_WRITE, EV_ADD);
}

sub readers {
    my $self    = shift;
    my @readers = ();

    foreach my $event ($self->_events) {
        my ($fd, $filter, $flags, $fflags, $data, $udata) = @$event;

        if ($filter == EVFILT_READ) {
            push @readers, $fd;
        }
    }

    return @readers;
}

sub writers {
    my $self    = shift;
    my @writers = ();

    foreach my $event ($self->_events) {
        my ($fd, $filter, $flags, $fflags, $data, $udata) = @$event;

        if ($filter == EVFILT_WRITE) {
            push @writers, $fd;
        }
    }

    return @writers;
}

sub errors { () }

sub hups { () }

sub remove {
    eval {
        $_[0]->_set($_[1], EVFILT_READ,  EV_DELETE);
        $_[0]->_set($_[1], EVFILT_WRITE, EV_DELETE);
    };
}

1;
