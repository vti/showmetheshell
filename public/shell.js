function Shell(o) {
    var self = this;

    var container = $('#container');
    container.html('');

    self.close = function() {
    };

    self.init = function() {
        container.html('');

        container.append('<div id="shell"></div>');

        var shell = $('#shell');

        var spaces = '';
        for (var i = 1; i <= 80; i++) {
            spaces = spaces + "&nbsp;";
        }

        shell.append('<div class="row space">' + spaces + '</div>');
        for (var i = 1; i <= 24; i++) {
            shell.append('<div class="row" id="row' + i + '">&nbsp;</div>');
        }
        shell.append('<div class="row space">' + spaces + '</div>');

        self.bind();
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
            if (!e.shiftKey && e.keyCode && (code >= 37 && code <= 40)) {
                return false;
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
        self.onsend($.toJSON(message));
    };

    self.updateRow = function(n, data) {
        var row = $('#row' + n);
        row.html(data);
    };
}
