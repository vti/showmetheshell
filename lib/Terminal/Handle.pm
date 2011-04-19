package Terminal::Handle;

use strict;
use warnings;

use IO::Handle;
use AnyEvent::Handle;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{handle} = AnyEvent::Handle->new(
        fh      => $self->{fh},
        on_read => sub {
            my $handle = shift;

            my $chunk = $handle->rbuf;
            $handle->rbuf = '';

            $self->{on_read}->($self, $chunk);
        },
        on_eof => sub {
            my $handle = shift;

            $self->{on_eof}->($self);
        },
        on_error => sub {
            my $handle = shift;
            my ($is_fatal, $message) = @_;

            $self->{on_error}->($message);
        }
    );

    return $self;
}

sub new_from_fd {
    my $class = shift;
    my $fd    = shift;

    my $fh = IO::Handle->new_from_fd($fd, 'w+');

    return $class->new(fh => $fh, @_);
}

sub write {
    my $self = shift;
    my ($chunk, $cb) = @_;

    $self->{handle}->push_write($chunk);

    if ($cb) {
        warn 'on_drain';
        $self->{handle}->on_drain(
            sub {
                $self->{handle}->on_drain(undef);

                $cb->($self);
            }
        );
    }

    return $self;
}

1;
