package EventReactor::Stateful;

use strict;
use warnings;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub state { @_ > 1 ? $_[0]->{state} = $_[1] : $_[0]->{state} }
sub done { shift->state('done') }
sub is_state { shift->state eq shift }
sub is_done  { shift->state eq 'done' }

1;
