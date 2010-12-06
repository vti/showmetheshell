package EventReactor::Loop::Poll;

use strict;
use warnings;

use IO::Poll qw/POLLIN POLLOUT POLLHUP POLLERR/;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    my $self = {@_};
    bless $self, $class;

    $self->{poll} = IO::Poll->new;

    return $self;
}

sub poll { shift->{poll} }

sub tick {
    my $self    = shift;
    my $timeout = shift;

    if ($self->poll->handles) {
        $self->poll->poll($timeout);
    }
    else {
        select(undef, undef, undef, $timeout);
    }
}

sub mask_rw { $_[0]->poll->mask($_[1] => POLLIN | POLLOUT) }
sub mask_ro { $_[0]->poll->mask($_[1] => POLLIN) }
sub mask_wo { $_[0]->poll->mask($_[1] => POLLOUT) }

sub readers {
    map {fileno $_} shift->poll->handles(POLLIN);
}

sub writers {
    map {fileno $_} shift->poll->handles(POLLOUT);
}

sub errors {
    map {fileno $_} shift->poll->handles(POLLERR);
}

sub hups {
    map {fileno $_} shift->poll->handles(POLLHUP);
}

sub remove { shift->poll->remove(@_) }

1;
