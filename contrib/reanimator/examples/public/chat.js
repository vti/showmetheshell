function Chat(options) {
    var chat = this;

    this.init = function() {
        var container = $('#container');

        container.html('');
        container.append('<div id="websocket-chat"></div>');
        $('#websocket-chat').append('<pre id="websocket-chat-log" style="height:200px; overflow: auto;"></pre>');
        $('#websocket-chat').append('<form id="websocket-chat-form"><input id="websocket-chat-input" style="width:90%" /></form>');
        $('#websocket-chat-form').submit(function() {
            var message = $('#websocket-chat-input').val().substring(0, 140);
            $('#websocket-chat-input').val('');
            if (message && message != '') {
                chat.send(message);
            }
            return false;
        });
    };

    this.read = function(message) {
        var log = $('#websocket-chat-log');
        log.append(message + "\n");
        log.animate({scrollTop: log[0].scrollHeight});
    };

    this.send = function(message) {
        chat.onsend(message);
    };
}
