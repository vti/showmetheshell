package Protocol::WebSocket;

use strict;
use warnings;

our $VERSION = 0.0004;

1;
__END__

=head1 NAME

Protocol::WebSocket - WebSocket protocol

=head1 DESCRIPTION

Client/server WebSocket message and frame parser/constructor. This module does
not provide a WebSocket server or client, but is made for using in http servers
or clients to provide WebSocket support.

L<Protocol::WebSocket> itself does not contain any code and cannot be used
directly. Instead the following modules should be used:

=head2 L<Protocol::WebSocket::Handshake::Server>

Server handshake parser and constructor.

=head2 L<Protocol::WebSocket::Handshake::Client>

Client handshake parser and constructor.

=head2 L<Protocol::WebSocket::Frame>

WebSocket frame parser and constructor.

=head2 L<Protocol::WebSocket::Request>

Low level WebSocket request parser and constructor.

=head2 L<Protocol::WebSocket::Response>

Low level WebSocket response parser and constructor.

=head2 L<Protocol::WebSocket::URL>

Low level WebSocket url parser and constructor.

=head1 EXAMPLES

For examples on how to use L<Protocol::WebSocket> with various event loops see
C<examples/> directory in the distribution.

=head1 CREDITS

Paul "LeoNerd" Evans

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2010, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
