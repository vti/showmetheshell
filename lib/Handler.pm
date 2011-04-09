package Handler;

use strict;
use warnings;

use Terminal;
use Encode ();
use JSON   ();

my $ESCAPE = pack('C', 0x1B);

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

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

                $text = Encode::decode_utf8($text);

                $text =~ s/$ESCAPE\[(.*?)m/&_insert_color($1)/ge;

                my $message = JSON->new->encode(
                    {type => 'row', row => $row, text => $text});
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

sub _insert_color {
    my $color = shift;

    my %colors = (
        0 => 'reset',
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
    );

    my @attrs = split ';' => $color;

    my $string = '';
    foreach my $attr (@attrs) {
        if (my $class = $colors{$attr}) {
            $string .= '</span>' if $class eq 'reset';

            $string .= qq/<span class="$class">/;

            $string .= '</span>' if $class eq 'reset';
        }
    }

    return $string;
}

1;
