#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'Protocol::WebSocket',
    VERSION_FROM => 'lib/Protocol/WebSocket.pm',
    ABSTRACT     => 'WebSocket request/response',
    AUTHOR       => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'http://github.com/vti/protocol-websocket',
                    bugtracker =>
                      'http://github.com/vti/protocol-websocket/issues'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {
        'Carp'         => 0,
        'Digest::MD5'  => 0,
        'Scalar::Util' => 0
    },
    test => {TESTS => 't/*.t t/*/*.t'}
);
