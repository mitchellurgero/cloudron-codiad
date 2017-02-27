## Cloudron LAMP Stack

LAMP is an archetypal model of web service stacks, named as an acronym of the names of its original four open-source components: the Linux operating system,
the Apache HTTP Server, the MySQL relational database management system (RDBMS), and the PHP programming language.

### SFTP

This app also bundles [ProFTPD](http://www.proftpd.org/) which provides `sftp://` access. Use your preferred ftp client to manage all files on the server. The `public` folder contains your PHP files. You will find `php.ini` at the root directory.


### Remote Terminal

Use `cloudron exec` for a remote shell connection into the app to adjust configuration files like `php.ini`.
See [here](https://cloudron.io/references/cli.html) for how to get the `cloudron` command line tool.


### Execution Environment

If you want to run for example a custom WordPress within this app, please note that the code will run behind a nginx proxy.
Apps like WordPress require you to let the app know about that fact.
For WordPress you would need to put this code into `wp-config.php`:

```
/*
 http://cmanios.wordpress.com/2014/04/12/nginx-https-reverse-proxy-to-wordpress-with-apache-http-and-different-port/
 http://wordpress.org/support/topic/compatibility-with-wordpress-behind-a-reverse-proxy
 https://wordpress.org/support/topic/wp_home-and-wp_siteurl
 */
// If WordPress is behind reverse proxy which proxies https to http
if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];

    if ($_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https')
        $_SERVER['HTTPS']='on';
}
```
