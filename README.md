## cloudron-codiad

----------

Built from https://git.cloudron.io/cloudron/lamp-app

## Special Information

- Due to either my limited knowledge of Cloudron, or a limitation of Cloudron itself, I had to generate a password for the app on first app installation.
  This means the `--password` flag is set in CLI. It is plaintext, but better than the random password that is generated on each boot.
  That said, you can change this first time generated password in `/app/data/temp` and then clicking "Configure" in the apps configuration screen

- **I am not able to test the security of this app, however, given a strong enough password, things should be fine. In either case, I would NOT INSTALL ON PRODUCTION SYSTEMS**

- I did not make VSCode or code-server. I just built this *very* *alpha* build of cloudron-vscode. Please, use at your own risk.

## Currently Installed Packages / Supported Languages

- Follows Cloudron:base:1.0.0 (See: [Cloudron Baseimage Packages](https://cloudron.io/developer/baseimage/#packages)
- Built off Cloudron's LAMP App

**Supported Langauges**

(If I missed one, let me know by opening an issue or Pull Request.)

- JavaScript
- PHP5/7 (PHP 7.0.3 installed, which is backwards compatible with most PHP5 functions and scripts)
- HTML

## Installing on Cloudron
- Make sure you have [Cloudron CLI installed](https://cloudron.io/developer/cli/) on a Linux computer that is NOT your cloudron server. (See docs for details)
- Then do the following:

```
cloudron login
cloudron install --image mitchellurgero/org.urgero.codiad:latest # Might need to change to whatever the latest build is.
```

## Building from source

- **Building and using Build Service to deploy**

```bash
git clone https://github.com/mitchellurgero/cloudron-codiad
cd cloudron-codiad
cloudron login
cloudron build
# Optional
cloudron install
```


- **Building and using local docker to deploy**

*Note: The below instructions have not been tested, please open an issue if they do not work.*

```bash
git clone https://github.com/mitchellurgero/cloudron-codiad
cd cloudron-codiad

## Change as you need!
docker build -t dockername/projectname:tagname .
docker push dockername/projectname:tagname

## End docker changes
cloudron login
cloudron install --image dockerhuburl/dockername/projectname:tagname
```


## Special Ports

- Port 2222 can be used for SFTP.

## Other Considerations

- Logos, Trademarks, etc are copyright of their respective owners.
