package Handler;

use strict;
use warnings;

use Terminal;
use Terminal::Ascii2Html;
use JSON ();

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{ascii2html} = Terminal::Ascii2Html->new;

    return $self;
}

sub run {
    my $handler = shift;

    my $cmd = $handler->{cmd};

    return sub {
        my $self = shift;

        my $terminal = Terminal->new(
            cmd            => $cmd,
            on_row_changed => sub {
                my ($terminal, $row, $text) = @_;

                $text = $handler->{ascii2html}->htmlify($text);

                my $message = JSON->new->encode(
                    {type => 'row', row => $row, text => $text});
                $self->send_message($message);
            },
            on_cursor_move => sub {
                my ($terminal, $x, $y) = @_;

                my $message =
                  JSON->new->encode({type => 'cursor', x => $x, y => $y});
                $self->send_message($message);
            },
            on_finished => sub {
                my $terminal = shift;

                $self->disconnect;
            }
        );

        $self->on_message(
            sub {
                my ($self, $message) = @_;

                my $json = JSON->new;

                eval { $message = $json->decode($message); };
                return if !$message || $@;

                my $type = $message->{type};
                if ($type eq 'key') {
                    my $buffer;

                    my $code = $message->{code};

                    $terminal->key($code);
                }
                elsif ($type eq 'action') {
                    $terminal->move($message->{action});
                }
                else {
                    warn "Unknown type '$type'";
                }
            }
        );

        $self->on_disconnect(
            sub {
            }
        );

        $terminal->start;
    };
}

1;
