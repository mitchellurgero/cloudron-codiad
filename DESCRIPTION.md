This app only supports <upstream>PHP 7.2</upstream>

## Cloudron LAP Stack with Codiad

(MySQL / MariaDB not installed.)

### SFTP

This app also bundles [ProFTPD](http://www.proftpd.org/) which provides `sftp://` access. Use your preferred ftp client to manage all files on the server. The `public` folder contains your PHP files. You will find `php.ini` at the root directory.

### Cron

This app supports running one or more cronjobs. The jobs are specified using the standard crontab syntax.

## ionCube

ionCube is a PHP module extension that loads encrypted PHP files and speeds up webpages. ionCube is pre-installed
and enabled by default.

### Remote Terminal

Use the [web terminal](https://cloudron.io/documentation/apps/#web-terminal) for a remote shell connection into the
app to adjust configuration files like `php.ini`.

