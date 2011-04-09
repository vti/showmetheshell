use strict;
use warnings;

use Test::More tests => 1;

use_ok('Terminal::Color');

my $color = Terminal::Color->new;

my $string = pack('H*', '1b5b6d1b5b33313b34306d1b5b316d73681b5b6d');
is($color->colorize($string), '<span class="fg-red"><span class="bg-black"><span class="bright">sh</span></span></span>');
