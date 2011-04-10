use strict;
use warnings;

use Test::More tests => 3;

use_ok('Terminal::Ascii2Html');

my $a2h = Terminal::Ascii2Html->new;

my $string = pack('H*', '1b5b6d1b5b33313b34306d1b5b316d73681b5b6d');
is($a2h->colorize($string), '<span class="fg-red"><span class="bg-black"><span class="bright">sh</span></span></span>');

is($a2h->htmlify('1 > 2'), '1&nbsp;&gt;&nbsp;2');
