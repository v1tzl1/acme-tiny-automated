# acme-tiny-automated
Some scripts aiming at automating a letsencrypt certification with acme-tiny

## Howto use?

### Requirements
- sudo
- openssl
- a webserver (serving static files in a directory)
- a cron deamon

### Setup
1. clone acme-tiny-automated
2. run setup.sh script (it will open the configuration file first and runs the setup once the editor is closed)
3. (optional) to use an existing letsencrypt account, overwrite ${DIR_CERTS}/${ACCOUNT_KEY} with your existing key
4. set up domains in ${DIR_CERTS}/configs/ (set permissions to root.${USER_GEN} 0640)
5. create initial certs with `sudo -u ${USER_GEN} ${DIR_CERTS}/bin/new_cert.sh <DOMAIN>`

From now on a cronjob will check all your domains for which you have a config file and update them if they are about to expire in 20 days or less.
