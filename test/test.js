#!/usr/bin/env node

'use strict';

var execSync = require('child_process').execSync,
    expect = require('expect.js'),
    path = require('path'),
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
    var EVENT_TITLE = 'Meet the Cloudron Founders';
    var CONTACT_CN = 'Max Mustermann';
    var TEST_TIMEOUT = 50000;
    var app;

    function waitForElement(elem, callback) {
         browser.wait(until.elementLocated(elem), TEST_TIMEOUT).then(function () {
            browser.wait(until.elementIsVisible(browser.findElement(elem)), TEST_TIMEOUT).then(function () {
                callback();
            });
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

    it('can login', function (done) {
        browser.manage().deleteAllCookies();
        browser.get('https://' + app.fqdn);

        waitForElement(by.id('input_1'),function () {
            browser.findElement(by.id('input_1')).sendKeys(process.env.USERNAME);
            browser.findElement(by.id('input_2')).sendKeys(process.env.PASSWORD);
            browser.findElement(by.name('loginForm')).submit();
            browser.wait(until.elementLocated(by.xpath('//*[@aria-label="New Event"]')), TEST_TIMEOUT).then(function () { done(); });
        });
    });

    it('can create event', function (done) {
        browser.get('https://' + app.fqdn + '/SOGo/so/' + process.env.USERNAME + '/Calendar/view');

        waitForElement(by.xpath('//*[@aria-label="New Event"]'), function () {
            browser.findElement(by.xpath('//*[@aria-label="New Event"]')).click();

            // open animation
            browser.sleep(2000).then(function () {

                waitForElement(by.xpath('//*[@aria-label="Create a new event"]'), function () {
                    browser.findElement(by.xpath('//*[@aria-label="Create a new event"]')).click();

                    waitForElement(by.xpath('//*[@ng-model="editor.component.summary"]'), function () {
                        browser.findElement(by.xpath('//*[@ng-model="editor.component.summary"]')).sendKeys(EVENT_TITLE);
                        browser.findElement(by.xpath('//*[@ng-model="editor.component.summary"]')).submit();

                        waitForElement(by.xpath('//*[@aria-label="' + EVENT_TITLE + '"]'), done);
                    });
                });
            });
        });
    });

    it('event is present', function (done) {
        browser.get('https://' + app.fqdn + '/SOGo/so/' + process.env.USERNAME + '/Calendar/view');

        waitForElement(by.xpath('//*[@aria-label="' + EVENT_TITLE + '"]'), done);
    });

    it('can create contact', function (done) {
        browser.get('https://' + app.fqdn + '/SOGo/so/' + process.env.USERNAME + '/Contacts/view#/addressbooks/personal/card/new');

        waitForElement(by.xpath('//*[@aria-label="New Contact"]'), function () {
            browser.findElement(by.xpath('//*[@aria-label="New Contact"]')).click();

            // open animation
            browser.sleep(2000).then(function () {

                waitForElement(by.xpath('//*[@aria-label="Create a new address book card"]'), function () {
                    browser.findElement(by.xpath('//*[@aria-label="Create a new address book card"]')).click();

                    waitForElement(by.xpath('//*[@ng-model="editor.card.c_cn"]'), function () {
                        browser.findElement(by.xpath('//*[@ng-model="editor.card.c_cn"]')).sendKeys(CONTACT_CN);
                        browser.findElement(by.xpath('//*[@aria-label="Save"]')).click();

                        waitForElement(by.xpath('//*[text()="' + CONTACT_CN + '"]'), done);
                    });
                });
            });
        });
    });

    it('contact is present', function (done) {
        browser.get('https://' + app.fqdn + '/SOGo/so/' + process.env.USERNAME + '/Contacts/view');

        waitForElement(by.xpath('//*[text()="' + CONTACT_CN + '"]'), function () {
            done();
        });
    });

    it('backup app', function () {
        execSync('cloudron backup create --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('restore app', function () {
        execSync('cloudron restore --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('can login', function (done) {
        browser.manage().deleteAllCookies();
        browser.get('https://' + app.fqdn);

        waitForElement(by.id('input_1'), function () {
            browser.findElement(by.id('input_1')).sendKeys(process.env.USERNAME);
            browser.findElement(by.id('input_2')).sendKeys(process.env.PASSWORD);
            browser.findElement(by.name('loginForm')).submit();

            waitForElement(by.xpath('//*[@aria-label="New Event"]'), done);
        });
    });

    it('event is still present', function (done) {
        browser.get('https://' + app.fqdn + '/SOGo/so/' + process.env.USERNAME + '/Calendar/view');

        waitForElement(by.xpath('//*[@aria-label="' + EVENT_TITLE + '"]'), done);
    });

    it('contact is still present', function (done) {
        browser.get('https://' + app.fqdn + '/SOGo/so/' + process.env.USERNAME + '/Contacts/view');

        waitForElement(by.xpath('//*[text()="' + CONTACT_CN + '"]'), done);
    });

    it('move to different location', function () {
        browser.manage().deleteAllCookies();
        execSync('cloudron configure --wait --location ' + LOCATION + '2', { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
        var inspect = JSON.parse(execSync('cloudron inspect'));
        app = inspect.apps.filter(function (a) { return a.location === LOCATION + '2'; })[0];
        expect(app).to.be.an('object');
    });

    it('can login', function (done) {
        browser.manage().deleteAllCookies();
        browser.get('https://' + app.fqdn);

        waitForElement(by.id('input_1'), function () {
            browser.findElement(by.id('input_1')).sendKeys(process.env.USERNAME);
            browser.findElement(by.id('input_2')).sendKeys(process.env.PASSWORD);
            browser.findElement(by.name('loginForm')).submit();

            waitForElement(by.xpath('//*[@aria-label="New Event"]'), done);
        });
    });

    it('event is still present', function (done) {
        browser.get('https://' + app.fqdn + '/SOGo/so/' + process.env.USERNAME + '/Calendar/view');

        waitForElement(by.xpath('//*[@aria-label="' + EVENT_TITLE + '"]'), done);
    });

    it('contact is still present', function (done) {
        browser.get('https://' + app.fqdn + '/SOGo/so/' + process.env.USERNAME + '/Contacts/view');

        waitForElement(by.xpath('//*[text()="' + CONTACT_CN + '"]'), done);
    });

    it('uninstall app', function () {
        execSync('cloudron uninstall --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });
});
