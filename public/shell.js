function Shell(o) {
    var self = this;

    self.rw = o.rw;

    var container = $('#container');
    container.html('');

    container.html('Connecting...');

    self.ws = new WebSocket(o.url);

    self.ws.onerror = function(e) {
        container.html("Error: " + e);
    };

    self.ws.onopen = function() {
        container.html('Connected. Loading...');

        self.init();
    };

    self.ws.onmessage = function(e) {
        var data = $.evalJSON(e.data);
        var type = data.type;

        if (type == 'status') {
            $('#clients').html(data.clients);
        }
        else if (type == 'row') {
            self.updateRow(data.row, data.text);
        }
        else if (type == 'cursor') {
            //updateCursor(data.row, data.col);
        }
    };

    self.ws.onclose = function() {
        container.html('Disconnected. <a href="/">Reconnect</a>');
        $('#clients').html('n/a');
    }

    self.init = function() {
        container.html('');

        container.append('<div class="menu"><a href="/">Reconnect</a> <a href="#" id="disconnect">Disconnect</a></div>');
        if (self.rw) {
            container.append('<div id="shell"></div>');
        }
        else {
            container.append('<div id="shell" class="readonly"></div>');
        }

        var shell = $('#shell');

        var spaces = '';
        for (var i = 1; i <= 80; i++) {
            spaces = spaces + "&nbsp;";
        }

        for (var i = 1; i <= 24; i++) {
            shell.append('<div class="row" id="row' + i + '">&nbsp;</div>');
        }
        shell.append('<div class="row space">' + spaces + '</div>');

        $('#disconnect').click(function () {
            self.ws.close();
            return false;
        });

        if (self.rw) {
            self.bind();
        }
    };

    self.bind = function() {
        $(document).bind('keyup', function (e) {
            var code = e.keyCode || e.which;
            if (code == 27) {
                self.sendMessage({"type":"key","code":code});
            }
        });

        $(document).bind('keypress', function(e) {
            var code = e.keyCode || e.which;

            if (e.ctrlKey) {
                // Firefox
                if (code >= 97) {
                code -= 96;
                }

                self.sendMessage({"type":"key","code":code});
                return true;
            }

            // Pass arrows
            if (!e.shiftKey && (code >= 37 && code <= 40)) {
                return;
            }

            // Unicode?
            if (e.charCode > 128) {
                code = e.charCode;
            }

            self.sendMessage({"type":"key","code":code});

            return false;
        });

        $(document).keydown(function (e) {
            var code = (e.keyCode ? e.keyCode : e.which);

            // Enter and tab
            if (code == 8 || code == 9) {
                self.sendMessage({"type":"key","code":code});

                return false;
            }

            if (!e.shiftKey && (code >= 37 && code <= 40)) {
                var action;

                switch (code) {
                    case 37: action = 'left'; break;
                    case 38: action = 'up'; break;
                    case 39: action = 'right'; break;
                    case 40: action = 'down'; break;
                }

                self.sendMessage({"type":"action","action":action});
                return false;
            }
        });
    };

    self.sendMessage = function (message) {
        self.ws.send($.toJSON(message));
    };

    self.updateRow = function(n, data) {
        var row = $('#row' + n);
        row.html(data);
    };

    //function updateCursor(r, c) {
    //    //var row = $('#row' + r);
    //    //row.append('<span class="cursor">&nbsp;</span>');
    //    //alert('cursor!');
    //}
}
