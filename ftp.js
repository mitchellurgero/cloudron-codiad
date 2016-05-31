var ftpd = require('ftpd'),
    fs = require('fs'),
    superagent = require('superagent'),
    path = require('path');

var simpleAuth = process.env.SIMPLE_AUTH_URL && process.env.SIMPLE_AUTH_CLIENT_ID && process.env.API_ORIGIN;

function verifyUser(username, password, callback) {
    if (!simpleAuth) {
        if (username === 'test' && password === 'test') return callback(null);
        else return callback(new Error('auth failed'));
    }

    var authPayload = {
        clientId: process.env.SIMPLE_AUTH_CLIENT_ID,
        username: username,
        password: password
    };

    superagent.post(process.env.SIMPLE_AUTH_URL + '/api/v1/login').send(authPayload).end(function (error, result) {
        if (error && error.status === 401) return callback(new Error('auth failed'));
        if (error) return callback(wrapRestError(error));
        if (result.status !== 200) return callback(new Error('auth failed'));

        callback(null);
    });
}

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
    pasvPortRangeStart: process.env.FTP_PORT_PASV_0 || 7003,
    pasvPortRangeEnd: process.env.FTP_PORT_PASV_3 || 7006,
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
        if (user) {
            username = user;
            success();
        } else {
            failure();
        }
    });

    connection.on('command:pass', function(password, success, failure) {
        if (!password) return failure();

        verifyUser(username, password, function (error) {
            if (error) failure();
            else success(username);
        });
    });
});

server.debugging = 4;
server.listen(options.port);
console.log('Listening on port ' + options.port);
