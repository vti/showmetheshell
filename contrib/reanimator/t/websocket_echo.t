#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

#BEGIN { $ENV{EVENT_REACTOR_DEBUG} = 1 }

use ReAnimator;

my $reanimator = ReAnimator->new(
    address   => 'localhost',
    port      => 3000,
    on_accept => sub {
        my ($self, $client) = @_;

        $client->on_message(
            sub {
                my ($client, $message) = @_;

                is $message => 'Hello!';

                $self->stop;
            }
        );

        $client->send_message('Hello!');
    },
    on_connect => sub {
        my ($self, $server) = @_;

        $server->on_message(
            sub {
                my ($server, $message) = @_;

                $server->send_message($message);
            }
        );
    }
);

$reanimator->listen;
$reanimator->connect(url => 'ws://localhost:3000');

$reanimator->start;
