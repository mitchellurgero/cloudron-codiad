#!/usr/bin/env node

'use strict';

var execSync = require('child_process').execSync,
    expect = require('expect.js'),
    path = require('path'),
    util = require('util'),
    webdriver = require('selenium-webdriver');

var by = webdriver.By,
    until = webdriver.until;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

if (!process.env.USERNAME || !process.env.PASSWORD) {
    console.log('USERNAME and PASSWORD env vars need to be set');
    process.exit(1);
}

describe('Application life cycle test', function () {
    this.timeout(0);

    var chrome = require('selenium-webdriver/chrome');
    var server, browser = new chrome.Driver();

    before(function (done) {
        var seleniumJar= require('selenium-server-standalone-jar');
        var SeleniumServer = require('selenium-webdriver/remote').SeleniumServer;
        server = new SeleniumServer(seleniumJar.path, { port: 4444 });
        server.start();

        done();
    });

    after(function (done) {
        browser.quit();
        server.stop();
        done();
    });

    var LOCATION = 'test';
    var TEST_TIMEOUT = 50000;
    var app;

    function waitForElement(elem, callback) {
         browser.wait(until.elementLocated(elem), TEST_TIMEOUT).then(function () {
            browser.wait(until.elementIsVisible(browser.findElement(elem)), TEST_TIMEOUT).then(function () {
                callback();
            });
        });
    }

    function welcomePage(callback) {
        browser.get('https://' + app.fqdn);

        waitForElement(by.xpath('//*[text()="Cloudron LAMP App"]'), function () {
            waitForElement(by.xpath('//*[text()="PHP Version 7.0.15-0ubuntu0.16.04.4"]'), callback);
        });
    }

    function uploadedFileExists(callback) {
        browser.get('https://' + app.fqdn + '/test.php');

        waitForElement(by.xpath('//*[text()="this works"]'), function () {
            waitForElement(by.xpath('//*[text()="' + app.fqdn + '"]'), callback);
        });
    }

    xit('build app', function () {
        execSync('cloudron build', { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('install app', function () {
        execSync('cloudron install --new --wait --location ' + LOCATION, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('can get app information', function () {
        var inspect = JSON.parse(execSync('cloudron inspect'));

        app = inspect.apps.filter(function (a) { return a.location === LOCATION; })[0];

        expect(app).to.be.an('object');
    });

    it('can view welcome page', welcomePage);
    it('can upload file with sftp', function () {
        // remove from known hosts in case this test was run on other apps with the same domain already
        execSync(util.format('sed -i \'/%s/d\' -i ~/.ssh/known_hosts', app.fqdn));
        execSync(util.format('lftp sftp://%s:%s@%s:%s  -e "set sftp:auto-confirm yes; cd public/; put test.php; bye"', process.env.USERNAME, process.env.PASSWORD, app.fqdn, app.portBindings.SFTP_PORT));
    });
    it('can get uploaded file', uploadedFileExists);

    it('backup app', function () {
        execSync('cloudron backup create --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('restore app', function () {
        execSync('cloudron restore --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('can get uploaded file', uploadedFileExists);

    it('move to different location', function () {
        browser.manage().deleteAllCookies();
        execSync('cloudron configure --wait --location ' + LOCATION + '2 --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
        var inspect = JSON.parse(execSync('cloudron inspect'));
        app = inspect.apps.filter(function (a) { return a.location === LOCATION + '2'; })[0];
        expect(app).to.be.an('object');
    });

    it('can get uploaded file', uploadedFileExists);

    it('uninstall app', function () {
        execSync('cloudron uninstall --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });
});
