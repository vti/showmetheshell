#!/usr/bin/env perl

{

    package EchoStream;
    use Moose;
    extends 'Reflex::Stream';
    use Protocol::WebSocket::Handshake::Server;
    use Protocol::WebSocket::Frame;

    has hs => (
        is      => 'ro',
        isa     => 'Protocol::WebSocket::Handshake::Server',
        default => sub { Protocol::WebSocket::Handshake::Server->new() },
    );

    has frame => (
        is      => 'ro',
        isa     => 'Protocol::WebSocket::Frame',
        default => sub { Protocol::WebSocket::Frame->new() },
    );

    sub on_data {
        my ($self, $args) = @_;

        my $hs = $self->hs;
        unless ($hs->is_done) {
            $hs->parse($args->{data});
            $self->put($hs->to_string) if $hs->is_done;
            return;
        }

        my $frame = $self->frame;
        $frame->append($args->{data});
        while (my $message = $frame->next) {
            $self->put($frame->new($message)->to_string);
        }
    }
}

{

    package TcpEchoServer;

    use Moose;
    extends 'Reflex::Acceptor';
    use Reflex::Collection;

    has_many clients => (handles => {remember_client => "remember"});

    sub on_accept {
        my ($self, $args) = @_;
        $self->remember_client(
            EchoStream->new(handle => $args->{socket}, rd => 1));
    }
}

TcpEchoServer->new(
    listener => IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 3000,
        Listen    => 5,
        Reuse     => 1,
    )
)->run_all;
