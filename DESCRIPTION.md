Empty LAMP Stack.

Use `cloudron push` to copy files into `/app/data/public/` and `cloudron exec` to get a remote terminal.

See [here](https://cloudron.io/references/cli.html) for how to get the `cloudron` command line tool.

This app also has webdav enabled to work with the public folder. Prepend `/webdav/` to your applications url and connect with a webdav enabled client.

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
