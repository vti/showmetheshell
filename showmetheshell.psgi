use strict;
use warnings;

use lib 'lib';

use Plack::Builder;

use Handler;
use Text::Caml;

my $caml = Text::Caml->new(templates_path => 'templates');

my $app = sub {
    my $env = shift;

    my $content = $caml->render_file('index.caml', {});

    return [   200,
        ['Content-Type' => 'text/html', 'Content-Length' => length($content)],
        [$content]
    ];
};

builder {
    enable "Static",
      path => qr/\.(?:js|css|jpe?g|gif|png|html?|swf|ico)$/,
      root => 'htdocs';

    enable "SocketIO",
        instance => Handler->new(cmd => '/bin/sh');

    $app;
};
