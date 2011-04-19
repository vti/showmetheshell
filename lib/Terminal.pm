package Terminal;

use strict;
use warnings;

use IO::Pty;
use POSIX ();
use Term::VT102 ();

use Terminal::Handle;

use constant DEBUG => $ENV{TERMINAL_DEBUG};

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{history} = [];
    $self->{created} = time;

    $self->{cols} ||= 80;
    $self->{rows} ||= 24;

    $self->{cmd} ||= '/bin/sh';

    $self->{on_row_chainged} ||= sub { };
    $self->{on_cursor_move}  ||= sub { };
    $self->{on_finished}     ||= sub { };

    $self->init;

    return $self;
}

sub on_row_changed {
    @_ > 1 ? $_[0]->{on_row_changed} = $_[1] : $_[0]->{on_row_changed};
}

sub on_cursor_move {
    @_ > 1 ? $_[0]->{on_cursor_move} = $_[1] : $_[0]->{on_cursor_move};
}

sub on_finished {
    @_ > 1 ? $_[0]->{on_finished} = $_[1] : $_[0]->{on_finished};
}

sub init {
    my $self = shift;

    DEBUG && warn "Creating Term::VT102\n";

    my $vt = Term::VT102->new(cols => $self->{cols}, rows => $self->{rows});

    # Convert linefeeds to linefeed + carriage return.
    $vt->option_set('LFTOCRLF', 1);

    # Make sure line wrapping is switched on.
    $vt->option_set('LINEWRAP', 1);

    DEBUG && warn "Creating IO::Pty\n";
    my $pty = IO::Pty->new;

    my $tty_name = $pty->ttyname;
    if (not defined $tty_name) {
        die "Could not assign a pty";
    }
    $pty->autoflush;

    $self->{vt}  = $vt;
    $self->{pty} = $pty;

    return $self;
}

sub start {
    my $self = shift;

    DEBUG && warn "Starting a new process\n";

    my $vt  = $self->vt;
    my $pty = $self->pty;
    my $cmd = $self->cmd;

    my $shell_pid = _spawn_shell($vt, $pty, $cmd);
    $self->{shell_pid} = $shell_pid;

    $self->{handle} = $self->_build_handle;

    $vt->callback_set(
        OUTPUT => sub {
            my ($vtobject, $type, $arg1, $arg2, $private) = @_;

            if ($type eq 'OUTPUT') {
                $self->write($arg1);
            }
          } => $pty
    );

    my $changedrows = $self->{changedrows} = {};

    $vt->callback_set('ROWCHANGE',   \&_vt_rowchange, $changedrows);
    $vt->callback_set('CLEAR',       \&_vt_changeall, $changedrows);
    $vt->callback_set('SCROLL_UP',   \&_vt_changeall, $changedrows);
    $vt->callback_set('SCROLL_DOWN', \&_vt_changeall, $changedrows);
    $vt->callback_set('GOTO',        \&_vt_cursormove, $self);

    $self->{spawned} = 1;

    return $self;
}

sub changedrows { shift->{changedrows} }
sub created     { shift->{created} }
sub history     { shift->{history} }
sub pty         { shift->{pty} }
sub shell_pid   { shift->{shell_pid} }
sub vt          { shift->{vt} }
sub cmd         { shift->{cmd} }

sub is_spawned { shift->{spawned} }

sub read {
    my $self = shift;
    my ($chunk) = @_;

    $self->on_finished->($self), return
      if waitpid($self->shell_pid, POSIX::WNOHANG) > 0;

    $self->vt->process($chunk);

    foreach my $row (sort keys %{$self->changedrows}) {
        my $text = $self->vt->row_sgrtext($row);
        delete $self->changedrows->{$row};

        $self->history->[$row - 1] = $text;

        DEBUG && warn "row $row changed: $text\n";
        $self->on_row_changed->($self, $row, $text);
    }
}

sub write {
    my $self = shift;

    $self->{handle}->write(@_);

    return $self;
}

sub key {
    my $self = shift;
    my $code = shift;

    my $buffer;

    if ($code < 128) {
        $buffer = pack('C', $code);
    }
    elsif ($code > 128 && $code < 2048) {
        my $one = ($code >> 6) | 192;
        my $two = ($code & 63) | 128;
        $buffer = pack('CC', $one, $two);
    }
    else {
        my $one   = (($code >> 12) | 224);
        my $two   = ((($code >> 6) & 63) | 128);
        my $three = (($code & 63) | 128);
        $buffer = pack('CCC', $one, $two, $three);
    }

    $self->write($buffer);
}

sub left  { shift->move('left') }
sub up    { shift->move('up') }
sub right { shift->move('right') }
sub down  { shift->move('down') }

sub move {
    my $self = shift;
    my ($direction) = @_;

    my $buffer;

    if ($direction eq 'left') {
        $buffer = "\e\[D";
    }
    elsif ($direction eq 'up') {
        $buffer = "\e\[A";
    }
    elsif ($direction eq 'right') {
        $buffer = "\e\[C";
    }
    elsif ($direction eq 'down') {
        $buffer = "\e\[B";
    }
    else {
        return;
    }

    warn "move $direction";

    $self->write($buffer);
}

sub _build_handle {
    my $self = shift;

    $self->{handle} ||= Terminal::Handle->new_from_fd(
        $self->pty->fileno,
        on_read => sub {
            my $handle = shift;
            my ($chunk) = @_;

            $self->read($chunk);
        },
        on_eof => sub {
        },
        on_error => sub {
        }
    );

    return $self->{handle};
}

sub _vt_rowchange {
    my ($vtobject, $type, $arg1, $arg2, $private) = @_;

    $private->{$arg1} = time if (not exists $private->{$arg1});
}

sub _vt_changeall {
    my ($vtobject, $type, $arg1, $arg2, $private) = @_;

    for (my $row = 1; $row <= $vtobject->rows; $row++) {
        $private->{$row} = 0;
    }
}

sub _vt_cursormove {
    my ($vtobject, $type, $arg1, $arg2, $self) = @_;

    #$self->on_cursor_move->($self, $arg1, $arg2);
}

sub _spawn_shell {
    my ($vt, $pty, $cmd) = @_;

    my $pid = fork;
    if (not defined $pid) {
        die "Cannot fork: $!";
    }
    elsif ($pid == 0) {
        warn 'Child forked' if DEBUG;

        # Child process - set up stdin/out/err and run the command.

        # Become process group leader.
        if (not POSIX::setsid()) {
            warn "Couldn't perform setsid: $!";
        }

        # Get details of the slave side of the pty.
        my $tty      = $pty->slave;
        my $tty_name = $tty->ttyname;

        $tty->set_raw;
        $pty->set_raw;

        $pty->make_slave_controlling_terminal;

        # File descriptor shuffling - close the pty master, then close
        # stdin/out/err and reopen them to point to the pty slave.
        close($pty);
        close(STDIN);
        close(STDOUT);
        open(STDIN, "<&" . $tty->fileno)
          || die "Couldn't reopen " . $tty_name . " for reading: $!";
        open(STDOUT, ">&" . $tty->fileno)
          || die "Couldn't reopen " . $tty_name . " for writing: $!";
        close(STDERR);
        open(STDERR, ">&" . $tty->fileno)
          || die "Couldn't redirect STDERR: $!";

        # Set sane terminal parameters.
        system 'stty sane';

        # Set the terminal size with stty.
        system 'stty rows ' . $vt->rows;
        system 'stty cols ' . $vt->cols;

        # Finally, run the command, and die if we can't.
        exec $cmd;
        die "Cannot exec '$cmd': $!";
    }
    else {
        return $pid;
    }
}

1;
