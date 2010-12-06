package EventReactor::Loop;

use strict;
use warnings;

use EventReactor::Loop::Poll;

sub build {
    return EventReactor::Loop::Poll->new
}

1;
