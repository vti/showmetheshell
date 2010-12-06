#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok 'ReAnimator';
