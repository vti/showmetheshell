package Terminal::Color;

use strict;
use warnings;

my $ESCAPE = pack('C', 0x1B);

my $COLORS = {
    0 => 'dull',
    1 => 'bright',
    2 => 'dim',
    4 => 'underscore',
    5 => 'blink',
    7 => 'reverse',
    8 => 'hidden',

    # Foreground Colours
    30 => 'fg-black',
    31 => 'fg-red',
    32 => 'fg-green',
    33 => 'fg-yellow',
    34 => 'fg-blue',
    35 => 'fg-magenta',
    36 => 'fg-cyan',
    37 => 'fg-white',

    # Background Colours
    40 => 'bg-black',
    41 => 'bg-red',
    42 => 'bg-green',
    43 => 'bg-yellow',
    44 => 'bg-blue',
    45 => 'bg-magenta',
    46 => 'bg-cyan',
    47 => 'bg-white',
};


sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub colorize {
    my $self = shift;
    my ($text) = @_;

    my $depth = 0;
    while ($text =~ s/$ESCAPE\[(.*?)m/&_insert_color($1, $depth)/e) {
        $depth++;
    }

    return $text;
}

sub _insert_color {
    my ($color, $depth) = @_;

    if ($depth && $color eq '') {
        my $string = '';
        $string .= '</span>' for (1 .. $depth);
        return $string;
    }

    my @attrs = split ';' => $color;

    my $string = '';
    foreach my $attr (@attrs) {
        if (my $class = $COLORS->{$attr}) {
            $string .= qq/<span class="$class">/;
        }
    }

    return $string;
}

1;
