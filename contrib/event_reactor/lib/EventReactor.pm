package EventReactor;

use strict;
use warnings;

use EventReactor::AcceptedAtom;
use EventReactor::ConnectedAtom;
use EventReactor::Loop;
use EventReactor::Timer;

use Errno qw/EAGAIN EWOULDBLOCK EINPROGRESS/;
use File::Spec;
use IO::Socket;
use Socket qw/IPPROTO_TCP TCP_NODELAY/;
require Carp;

use constant DEBUG => $ENV{EVENT_REACTOR_DEBUG} ? 1 : 0;

use constant IO_SOCKET_SSL => eval { require IO::Socket::SSL; 1 };

# openssl req -new -x509 -keyout cakey.pem -out cacert.pem -nodes -days 7300
use constant SSL_KEY => <<'EOF';
-----BEGIN PRIVATE KEY-----
MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBAMy4fNRWTlZ15y5w
yZyWN5L3POBm0K6FtXJL8WPI201fjKc5Ye55/hF4YNFIi5tF7krX9KEW1BDzZTCw
83lWAnkzpcgy4AuRPSiTWI1kINnOEtn3ae4+HYkIP9KIgVIPLHnuC5pzWBfdFBzU
UYtz+3fwnsBNFVhqJT2Iej54wPdLAgMBAAECgYEAmUNk8PLMIx6RvMrjpT8wy+4c
vUM75+xiMvd3+GRfCkYGXwsurgLWmu2sTgIpwk1QYOfcVN1qVmZh01ombShfIFaP
Y1AUrwfaBW2bgiUyOXmK3WdgycpMrhGI0KOhAWu0K5D13FOgbS6yRVNJMbDujxuE
m48qampjXZvO5jfwgoECQQDy+EWIIPvkF4fFX+VayIUceUdfz72HruVjcYjeaKEz
nSjxN3HaV3iS0n5B+Ilb+rZ0PR5XNj6mN2Pp7wx0lotzAkEA17MYD+1wyPD29fRm
alRJ8lFy8MV4UyMrOqnLX58HsmpWWHGUXb8gMSwvYqUeV3LVuDga0ucbU5KlJ5lV
y3IeyQJAeRcO4DdAEn8/pTiTv9jrrjMrRS7tkG+z1wnAYsfWfzi2LPGrBlxNtS6+
yfYpzvN2dxv2wRRByOkWHIKMvJZCzQJAI/J67hyaEULnRXInp0zIzhN43ltqhCB2
Ud5+QD9WnwtNvIuhOEZj7Q36D6yI8/X1XDAteDx/t1vXHlRVkgRA0QJATGt4aU84
NCzhfVIWR9wdMzuYkA8yaZrcUaKk3UKckxhGQOOwSFMB4HUbM9vTwz1VdFcjECWi
lOvmNA4Kx9riLA==
-----END PRIVATE KEY-----
EOF

use constant SSL_CERT => <<'EOF';
-----BEGIN CERTIFICATE-----
MIICZjCCAc+gAwIBAgIJAOfXxWTGTLcyMA0GCSqGSIb3DQEBBQUAMEwxCzAJBgNV
BAYTAkRFMRMwEQYDVQQIDApTb21lLVN0YXRlMRMwEQYDVQQKDApSZUFuaW1hdG9y
MRMwEQYDVQQDDApSZUFuaW1hdG9yMB4XDTEwMTEwNjIyMDYxMloXDTMwMTEwMTIy
MDYxMlowTDELMAkGA1UEBhMCREUxEzARBgNVBAgMClNvbWUtU3RhdGUxEzARBgNV
BAoMClJlQW5pbWF0b3IxEzARBgNVBAMMClJlQW5pbWF0b3IwgZ8wDQYJKoZIhvcN
AQEBBQADgY0AMIGJAoGBAMy4fNRWTlZ15y5wyZyWN5L3POBm0K6FtXJL8WPI201f
jKc5Ye55/hF4YNFIi5tF7krX9KEW1BDzZTCw83lWAnkzpcgy4AuRPSiTWI1kINnO
Etn3ae4+HYkIP9KIgVIPLHnuC5pzWBfdFBzUUYtz+3fwnsBNFVhqJT2Iej54wPdL
AgMBAAGjUDBOMB0GA1UdDgQWBBRPvH4ezMIfId3cqbEHnKMcPo2auzAfBgNVHSME
GDAWgBRPvH4ezMIfId3cqbEHnKMcPo2auzAMBgNVHRMEBTADAQH/MA0GCSqGSIb3
DQEBBQUAA4GBAEeySk5j1EAFkGphrKrODJG6UK/PmmDrUrFbr67cLZRwJ5qe+vGb
tpDETZXAYGvbO+ECLeTYqQoLqQN86d66PIBdWoRoBnNgd9P49GhFGOvnEZ4d8VHI
wKNBg8NajSWDIy9TVaaqrXggBTQNYNKsGiX3gDIwdooxE2dsEiYw+eE/
-----END CERTIFICATE-----
EOF

our $VERSION = '0.0001';

$SIG{PIPE} = 'IGNORE';

sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    my $self = {@_};
    bless $self, $class;

    $self->{max_clients} ||= 100;

    $self->{loop} = $self->_build_loop;

    $self->{on_accept} ||= sub { warn 'Unhandled on_accept event' if DEBUG };
    $self->{on_connect}
      ||= sub { warn 'Unhandled on_connect event' if DEBUG };
    $self->{on_error} ||= sub { warn 'Unhandled on_error event' if DEBUG };

    $self->{atoms}  = {};
    $self->{timers} = {};

    $self->{loop_timeout} ||= 0.25;

    $self->{accept_timeout} ||= 5;

    $self->{secure} ||= 0;

    return $self;
}

sub continue { @_ > 1 ? $_[0]->{continue} = $_[1] : $_[0]->{continue} }

sub accept_timeout {
    @_ > 1 ? $_[0]->{accept_timeout} = $_[1] : $_[0]->{accept_timeout};
}

sub secure    { @_ > 1 ? $_[0]->{secure}    = $_[1] : $_[0]->{secure} }
sub key_file  { @_ > 1 ? $_[0]->{key_file}  = $_[1] : $_[0]->{key_file} }
sub cert_file { @_ > 1 ? $_[0]->{cert_file} = $_[1] : $_[0]->{cert_file} }

sub loop_timeout {
    @_ > 1 ? $_[0]->{loop_timeout} = $_[1] : $_[0]->{loop_timeout};
}

sub on_accept  { @_ > 1 ? $_[0]->{on_accept}  = $_[1] : $_[0]->{on_accept} }
sub on_connect { @_ > 1 ? $_[0]->{on_connect} = $_[1] : $_[0]->{on_connect} }
sub on_error   { @_ > 1 ? $_[0]->{on_error}   = $_[1] : $_[0]->{on_error} }

sub loop    { shift->{loop} }
sub server  { shift->{server} }
sub address { shift->{address} }
sub port    { shift->{port} }

sub atoms  { shift->{atoms} }
sub timers { shift->{timers} }

sub max_clients {
    @_ > 1 ? $_[0]->{max_clients} = $_[1] : $_[0]->{max_clients};
}

sub listen {
    my $self = shift;

    if ($self->secure) {
        Carp::croak q/IO::Socket::SSL is required/ unless IO_SOCKET_SSL;

        Carp::croak
          q/Either both key_file AND cert_file must be specified or NEITHER of them, so default can be used/
          unless ($self->key_file && $self->cert_file)
          || (!$self->key_file && !$self->cert_file);
    }

    my $address = $self->address || $ENV{EVENT_REACTOR_ADDRESS} || '0.0.0.0';
    my $port    = $self->port    || $ENV{EVENT_REACTOR_PORT}    || '3000';

    my $socket = $self->_build_server_socket(
        address => $address,
        port    => $port
    );

    Carp::croak qq/Can't create server/ unless $socket;

    $self->{server} = $socket;

    $self->loop->mask_rw($self->server);

    print "Listening on $address:$port\n" if DEBUG;

    return $self;
}

sub connect {
    my $self   = shift;
    my %params = @_;

    my $address = delete $params{address} || $self->address;
    my $port    = delete $params{port}    || $self->port;

    Carp::croak q/address and port are required/ unless $address && $port;

    my $socket = delete $params{socket}
      || $self->_build_client_socket(%{delete $params{socket_args} || {}});

    my $atom = $self->_build_connected_atom(
        handle     => $socket,
        secure     => $self->secure,
        on_connect => sub {
            print "Connected\n" if DEBUG;

            $self->on_connect->($self, shift);
        },
        %params
    );

    $self->add_atom($atom);

    my $ip = gethostbyname($address);
    my $addr = sockaddr_in($port, $ip);

    print "Connecting to $address:$port...\n" if DEBUG;

    my $rv = $socket->connect($addr);

    if (defined $rv && $rv == 0) {
        $atom->connected;
    }
    elsif ($! == EINPROGRESS) {
        $atom->connecting;
    }
    else {
        $atom->error($!);
        $self->drop($atom);
        return;
    }

    return $atom;
}

sub start {
    my $self = shift;

    $self->continue(1);

    $self->_loop_until_i_die;
}

sub stop { shift->continue(0) }

sub add_atom {
    my $self = shift;
    my ($atom) = @_;

    $atom->on_write(sub { $self->loop->mask_rw($atom->handle) });

    $self->atoms->{$atom->handle->fileno} = $atom;

    $self->loop->mask_rw($atom->handle);
}

sub drop {
    my $self = shift;
    my $atom = shift;

    my $socket = $atom->handle;

    $self->loop->remove($socket);

    my $fd = $socket->fileno;

    if (my $e = $atom->error) {
        print "Connection error: $e\n" if DEBUG;
    }
    else {
        print "Connection closed\n" if DEBUG;

        $atom->disconnected;
    }

    delete $self->atoms->{$fd};
    delete $self->timers->{$fd};

    $socket->close;

    return $self;
}

sub set_timeout { shift->set_interval(@_, {one_shot => 1}) }

sub set_interval {
    my $self = shift;

    my $args     = ref $_[-1] eq 'HASH' ? pop : {};
    my $cb       = pop;
    my $fd       = @_ > 1 ? shift->handle->fileno : $self->server->fileno;
    my $name     = @_ > 1 ? shift : '';
    my $interval = shift;

    my $timer = $self->_build_timer(interval => $interval, cb => $cb, %$args);

    my $id = "$fd:" . ($name || "$timer");
    $self->_add_timer($id => $timer);

    return $self;
}

sub accepted_atoms {
    grep { $_->isa('EventReactor::AcceptedAtom'); $_ } values %{shift->atoms};
}

sub connected_atoms {
    grep { $_->isa('EventReactor::ConnectedAtom'); $_ }
      values %{shift->atoms};
}

sub _loop_until_i_die {
    my $self = shift;

    my $timeout = $self->loop_timeout;

    while (1) {
        $self->loop->tick($timeout);

        $self->_timers;

        for ($self->loop->readers) {
            $self->_read($_);
        }

        for ($self->loop->writers) {
            $self->_write($_);
        }

        for ($self->loop->errors) {
            $self->_error($_);
        }

        for ($self->loop->hups) {
            $self->_hup($_);
        }

        last unless $self->continue;

        last unless $self->server || scalar keys %{$self->atoms};
    }
}

sub _timers {
    my $self = shift;

    foreach my $id (keys %{$self->timers}) {
        my $timer = $self->timers->{$id};

        if ($timer->wake_up) {
            delete $self->timers->{$id} if $timer->one_shot;
        }
    }
}

sub _accept {
    my $self = shift;
    my $atom = shift;

    if (!$atom) {
        my $socket = $self->server->accept;
        return unless $socket;

        $socket->blocking(0);

        setsockopt($socket, IPPROTO_TCP, TCP_NODELAY, 1);

        print "New connection\n" if DEBUG;

        $atom = $self->_build_accepted_atom(
            secure    => $self->secure,
            handle    => $socket,
            on_accept => sub {
                $self->on_accept->($self, shift);
            }
        );

        unless ($self->secure) {
            $self->add_atom($atom);

            return $self->_atom_accepted($atom);
        }

        unless ($self->key_file && $self->cert_file) {
            my $tmp_dir = File::Spec->tmpdir;

            my $key_file  = File::Spec->catfile($tmp_dir, 'cakey.pem');
            my $cert_file = File::Spec->catfile($tmp_dir, 'cacert.pem');

            open my $key, '>', $key_file;
            print $key SSL_KEY;
            close $key;

            open my $cert, '>', $cert_file;
            print $cert SSL_CERT;
            close $cert;

            $self->key_file($key_file);
            $self->cert_file($cert_file);
        }

        $socket = IO::Socket::SSL->start_SSL(
            $socket,
            SSL_startHandshake => 0,
            SSL_server         => 1,
            SSL_key_file       => $self->key_file,
            SSL_cert_file      => $self->cert_file,
        );

        unless ($socket) {
            $self->drop($atom);
            return;
        }

        $socket->blocking(0);

        $self->add_atom($atom);

        $self->set_timeout(
            $atom => $self->accept_timeout => sub {
                $atom->error('Accept timeout.');
                $self->drop($atom);
            }
        );

        if ($socket->accept_SSL) {
            $self->loop->mask_rw($atom->handle);
            return $self->_atom_accepted($atom);
        }
        elsif ($! && $! == EAGAIN) {
            $self->loop->mask_ro($socket);
            return;
        }
    }
    else {
        my $socket = $atom->handle;

        $atom->{socket} = $socket;
        return $self->_atom_accepted($atom) if $socket->accept_SSL;
        return if $! && $! != EAGAIN;
    }

    $self->drop($atom);
}

sub _atom_accepted {
    my $self = shift;
    my $atom = shift;

    delete $self->timers->{$atom->handle->fileno};

    return $atom->accepted;
}

sub _read {
    my $self = shift;
    my $fd   = shift;

    return $self->_accept if $self->server && $fd == $self->server->fileno;

    my $atom = $self->atoms->{$fd};
    return unless $atom;

    return $self->_accept($atom) if $atom->is_accepting;

    my $rb = $atom->handle->sysread(my $chunk, 1024 * 4096);

    unless ($rb) {
        return if $! && $! == EAGAIN || $! == EWOULDBLOCK;

        $atom->error($!) if $!;
        return $self->drop($atom);
    }

    warn '< ', $chunk if DEBUG;

    my $read = $atom->read($chunk);

    return $self->drop($atom) unless defined $read;

    return;
}

sub _write {
    my $self = shift;
    my $fd   = shift;

    return $self->_accept if $self->server && $fd == $self->server->fileno;

    my $atom = $self->atoms->{$fd};
    return unless $atom;

    return $self->_accept($atom) if $atom->is_accepting;

    if ($atom->is_connecting) {
        unless ($atom->is_connected) {
            $self->error($!) if $!;
            return $self->drop($atom);
        }

        $atom->connected;
    }

    return $self->loop->mask_ro($atom->handle) unless $atom->is_writing;

    warn '> ' . $atom->buffer if DEBUG;

    my $br = $atom->handle->syswrite($atom->buffer);

    if (not defined $br) {
        return if $! == EAGAIN || $! == EWOULDBLOCK;

        $atom->error($!);
        return $self->drop($atom);
    }

    return $self->drop($atom) if $br == 0;

    $atom->bytes_written($br);

    $self->loop->mask_ro($atom->handle) unless $atom->is_writing;
}

sub _error {
    my $self = shift;
    my $fd   = shift;

    my $atom = $self->atoms->{$fd};
    return unless $atom;

    $atom->error($!);
    return $self->drop($atom);
}

sub _hup {
    my $self = shift;
    my $fd   = shift;

    my $atom = $self->atoms->{$fd};
    return unless $atom;

    return $self->drop($atom);
}

sub _add_timer {
    my $self  = shift;
    my $id    = shift;
    my $timer = shift;

    $self->timers->{$id} = $timer;
}

sub _build_loop { EventReactor::Loop->build }
sub _build_timer { shift; EventReactor::Timer->new(@_) }

sub _build_server_socket {
    my $self   = shift;
    my %params = @_;

    my $socket = IO::Socket::INET->new(
        Proto        => 'tcp',
        LocalAddress => delete $params{address},
        LocalPort    => delete $params{port},
        Type         => SOCK_STREAM,
        Listen       => SOMAXCONN,
        ReuseAddr    => 1,
        Blocking     => 0,
        %params
    ) or Carp::croak qq/Can't create a listen socket: $!/;

    $socket->blocking(0);

    return $socket;
}

sub _build_client_socket {
    my $self = shift;

    my $socket = IO::Socket::INET->new(
        Proto    => 'tcp',
        Type     => SOCK_STREAM,
        Blocking => 0,
        @_
    );

    $socket->blocking(0);

    return $socket;
}

sub _build_accepted_atom {
    my $self = shift;

    return EventReactor::AcceptedAtom->new(@_);
}

sub _build_connected_atom {
    my $self = shift;

    return EventReactor::ConnectedAtom->new(@_);
}

1;
