package Protocol::WebSocket::Response;

use strict;
use warnings;

use base 'Protocol::WebSocket::Message';

use Protocol::WebSocket::URL;
use Protocol::WebSocket::Cookie::Response;

require Carp;

sub location { @_ > 1 ? $_[0]->{location} = $_[1] : $_[0]->{location} }
sub secure   { @_ > 1 ? $_[0]->{secure}   = $_[1] : $_[0]->{secure} }

sub resource_name {
    @_ > 1 ? $_[0]->{resource_name} = $_[1] : $_[0]->{resource_name};
}

sub cookies { @_ > 1 ? $_[0]->{cookies} = $_[1] : $_[0]->{cookies} }

sub cookie {
    my $self = shift;

    push @{$self->{cookies}}, $self->_build_cookie(@_);
}

sub number1 { shift->_number('number1', 'key1', @_) }
sub number2 { shift->_number('number2', 'key2', @_) }

sub _number {
    my $self = shift;
    my ($name, $key, $value) = @_;

    my $method = "SUPER::$name";
    return $self->$method($value) if defined $value;

    $value = $self->$method();
    $value = $self->_extract_number($self->$key) if not defined $value;

    return $value;
}

sub key1 { @_ > 1 ? $_[0]->{key1} = $_[1] : $_[0]->{key1} }
sub key2 { @_ > 1 ? $_[0]->{key2} = $_[1] : $_[0]->{key2} }

sub to_string {
    my $self = shift;

    my $string = '';

    $string .= "HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a";

    $string .= "Upgrade: WebSocket\x0d\x0a";
    $string .= "Connection: Upgrade\x0d\x0a";

    Carp::croak(qq/host is required/) unless defined $self->host;

    my $location = $self->_build_url(
        host          => $self->host,
        secure        => $self->secure,
        resource_name => $self->resource_name,
    );
    my $origin = $self->origin ? $self->origin : 'http://' . $location->host;

    if ($self->version <= 75) {
        $string .= 'WebSocket-Protocol: ' . $self->subprotocol . "\x0d\x0a"
          if defined $self->subprotocol;
        $string .= 'WebSocket-Origin: ' . $origin . "\x0d\x0a";
        $string .= 'WebSocket-Location: ' . $location->to_string . "\x0d\x0a";
    }
    else {
        $string
          .= 'Sec-WebSocket-Protocol: ' . $self->subprotocol . "\x0d\x0a"
          if defined $self->subprotocol;
        $string .= 'Sec-WebSocket-Origin: ' . $origin . "\x0d\x0a";
        $string
          .= 'Sec-WebSocket-Location: ' . $location->to_string . "\x0d\x0a";
    }

    if (@{$self->cookies}) {
        $string .= 'Set-Cookie: ';
        $string .= join ',' => $_->to_string for @{$self->cookies};
        $string .= "\x0d\x0a";
    }

    $string .= "\x0d\x0a";

    $string .= $self->checksum if $self->version > 75;

    return $string;
}

sub _parse_first_line {
    my ($self, $line) = @_;

    unless ($line eq 'HTTP/1.1 101 WebSocket Protocol Handshake') {
        $self->error('Wrong response line');
        return;
    }

    return $self;
}

sub _parse_body {
    my $self = shift;

    if ($self->field('Sec-WebSocket-Origin')) {
        return 1 if length $self->{buffer} < 16;

        $self->version(76);

        my $checksum = substr $self->{buffer}, 0, 16, '';
        $self->checksum($checksum);
    }
    else {
        $self->version(75);
    }

    return $self if $self->_finalize;

    $self->error('Not a valid response');
    return;
}

sub _finalize {
    my $self = shift;

    my $location = $self->field('Sec-WebSocket-Location')
      || $self->field('WebSocket-Location');
    return unless defined $location;
    $self->location($location);

    my $url = $self->_build_url;
    return unless $url->parse($self->location);

    $self->secure($url->secure);
    $self->host($url->host);
    $self->resource_name($url->resource_name);

    $self->origin($self->field('Sec-WebSocket-Origin')
          || $self->field('WebSocket-Origin'));

    $self->subprotocol($self->field('Sec-WebSocket-Protocol')
          || $self->field('WebSocket-Protocol'));

    return 1;
}

sub _build_url    { shift; Protocol::WebSocket::URL->new(@_) }
sub _build_cookie { shift; Protocol::WebSocket::Cookie::Response->new(@_) }

1;
__END__

=head1 NAME

Protocol::WebSocket::Response - WebSocket Response

=head1 SYNOPSIS

    # Constructor
    $res = Protocol::WebSocket::Response->new(
        host          => 'example.com',
        resource_name => '/demo',
        origin        => 'file://',
        number1       => 777_007_543,
        number2       => 114_997_259,
        challenge     => "\x47\x30\x22\x2D\x5A\x3F\x47\x58"
    );
    $res->to_string; # HTTP/1.1 101 WebSocket Protocol Handshake
                     # Upgrade: WebSocket
                     # Connection: Upgrade
                     # Sec-WebSocket-Origin: file://
                     # Sec-WebSocket-Location: ws://example.com/demo
                     #
                     # 0st3Rl&q-2ZU^weu

    # Parser
    $res = Protocol::WebSocket::Response->new;
    $res->parse("HTTP/1.1 101 WebSocket Protocol Handshake\x0d\x0a");
    $res->parse("Upgrade: WebSocket\x0d\x0a");
    $res->parse("Connection: Upgrade\x0d\x0a");
    $res->parse("Sec-WebSocket-Origin: file://\x0d\x0a");
    $res->parse("Sec-WebSocket-Location: ws://example.com/demo\x0d\x0a");
    $res->parse("\x0d\x0a");
    $res->parse("0st3Rl&q-2ZU^weu");

=head1 DESCRIPTION

Construct or parse a WebSocket response.

=head1 ATTRIBUTES

=head2 C<host>

=head2 C<location>

=head2 C<origin>

=head2 C<resource_name>

=head2 C<secure>

=head1 METHODS

=head2 C<new>

Create a new L<Protocol::WebSocket::Response> instance.

=head2 C<parse>

    $res->parse($buffer);

Parse a WebSocket response. Incoming buffer is modified.

=head2 C<to_string>

Construct a WebSocket response.

=head2 C<cookie>

=head2 C<cookies>

=head2 C<key1>

    $self->key1;

Set or get C<Sec-WebSocket-Key1> field.

=head2 C<key2>

    $self->key2;

Set or get C<Sec-WebSocket-Key2> field.

=head2 C<number1>

    $self->number1;
    $self->number1(123456);

Set or extract from C<Sec-WebSocket-Key1> generated C<number> value.

=head2 C<number2>

    $self->number2;
    $self->number2(123456);

Set or extract from C<Sec-WebSocket-Key2> generated C<number> value.

=cut
