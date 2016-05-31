var ftpd = require('ftpd'),
    fs = require('fs'),
    path = require('path');

var server;
var options = {
    host: '0.0.0.0',
    port: process.env.FTP_PORT || 7002,
    tls: null,
};

server = new ftpd.FtpServer(options.host, {
    getInitialCwd: function() {
      return '/';
    },
    getRoot: function() {
      return '/app/data/public';
    },
    pasvPortRangeStart: process.env.FTP_PORT_PASSV_0 || 7003,
    pasvPortRangeEnd: process.env.FTP_PORT_PASSV_1 || 7004,
    tlsOptions: options.tls,
    allowUnauthorizedTls: true,
    useWriteFile: false,
    useReadFile: false
});

server.on('error', function(error) {
    console.log('FTP Server error:', error);
});

server.on('client:connected', function(connection) {
    var username = null;
    console.log('client connected: ' + connection.remoteAddress);
    connection.on('command:user', function(user, success, failure) {
        if (user === 'nebulon') {
            username = user;
            success();
        } else {
            failure();
        }
    });

    connection.on('command:pass', function(pass, success, failure) {
        if (pass === 'manda') {
            success(username);
        } else {
            failure();
        }
    });
});

server.debugging = 4;
server.listen(options.port);
console.log('Listening on port ' + options.port);
