use strict;
use warnings;

my $root;

BEGIN {
    use File::Basename ();
    use File::Spec     ();

    $root = File::Basename::dirname(__FILE__);
    $root = File::Spec->rel2abs($root);

    unshift @INC, "$root/../../lib";
}

use lib 'lib';

use Plack::Builder;
use Plack::App::File;

use Handler;
use Text::Caml;
use PocketIO;

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
    mount '/socket.io/static/flashsocket/WebSocketMain.swf' =>
      Plack::App::File->new(file => "$root/htdocs/WebSocketMain.swf");

    mount '/socket.io/static/flashsocket/WebSocketMainInsecure.swf' =>
      Plack::App::File->new(file => "$root/htdocs/WebSocketMainInsecure.swf");

    enable "Static",
      path => qr/\.(?:js|css|jpe?g|gif|png|html?|swf|ico)$/,
      root => 'htdocs';

    mount '/socket.io' =>
      PocketIO->new(instance => Handler->new(cmd => '/bin/bash'));

    mount '/' => builder {
        enable "Static",
          path => qr/\.(?:js|css|jpe?g|gif|png|html?|swf|ico)$/,
          root => "$root/public";

        $app;
    };
};
