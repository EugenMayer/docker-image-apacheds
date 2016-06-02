## WAT

Offers a build for apacheds forked from [greggigon great work](https://github.com/greggigon/apacheds) to add extensible configuration using ENV
This work is specifically created to be enable configuration in a rancher catalog like this [catalog](https://github.com/EugenMayer/kontextwork-catalog/tree/master/templates/apacheds)
but can be used for every environment.


Docker images will be published on [hub.docker.io](https://hub.docker.com/r/eugenmayer/apacheds/)

## Releases

For now, only planed to be published on [hub.docker.io](https://hub.docker.com/r/eugenmayer/apacheds/)

## Data

**IMPORTANT: Data is stored under /data - mount this on a named volume or the host to persist your date**

## Configuration

### DS Configuration

**IMPORTANT: Live-Configuration is stored under /confg - mount this on a named volume or the host**
The configuration will be stored on /conf and will persist on your volume. You can savely recreate the container, it will confgure automatically

**IMPORTANT: Bootstate is stored under /bootstrap - mount this on a named volume or the host**
Here you can either store your own config which gets imported once during the start of the start.
Then, the conf stored under /conf is used

To reimport your configuration once again, remove /bootstrap/config_imported and restart the container. This WILL REMOVE YOUR LIVE CONFIGURATION

#### a) Using the included template
You can configure the server using environment-variables. See the test/docker-compose.yml file for further informations or even this detailed (descriptions)[https://github.com/EugenMayer/kontextwork-catalog/tree/master/templates/apacheds/0/rancher-compose.yml]

+ DS_HOST: "example.dev" (The host your apacheds server will be reachable, used for the TLS certificate)

General Settings for SASL, see the [docs](http://directory.apache.org/apacheds/advanced-ug/4.1.2-sasl-authn.html)
+ DS_SASL_HOST: "example.dev"
+ DS_SASL_REALM: "EXAMPLE.DEV"
+ DS_SASL_DOMAIN: "EXAMPLE.DEV"
+ DS_SASL_BASEDN: "dc=example,dc=dev"

For now, Kerberos is disabled, but configure the REALM and BaseDN
+ DS_KRB_REALM: "EXAMPLE.DEV"
+ DS_KRB_BASEDN: "dc=example,dc=dev"

#### b) or using your own configuration
If you mount a folder with a config.ldif into /bootstrap, so /bootstrap/config.ldif, this file will be picked up
during the initial bootstrapped and imported as the configuration for apacheds. This way you can import your very own configuration.
If you already started the server once, you have to remove /bootstrap/config_imported first, then restart once again - your configuration
will now get imported.

### Configure TLS/startTLS

To add encryption, all you need is (also test/docker-compose.yml):

+ Mount a volume to /certs (see test/docker-compose.yml)
+ The folder you mount should include a fullchain.pem (certificate) and a privkey.pem ( private key ) file

During the start, the key and certificate will be added to a keystore (/boostrap/apacheds.keystore), so apacheDS can consume this

### Data persistence
To persist your data, please mount a volume on /data

### Importing your default data
To import your default entrys, add a file to your mounted /bootstrap/data.ldif and set the ENV variable BOOTSTRAP_FILE.
This ldif will be imported as data

### Using ur own schema
To use your own schema, add the folder to /bootstrap/schema, so it will be included during the boostrap

## Easy Testing

Checkout the repo, enter run

```
cd ./test
docker-compose up
```

Use [apachestudio](http://directory.apache.org/studio/downloads.html) to connect to the server, or whatever client you want
You need to add portus.dev and registry.dev to your /etc/hosts file and point it to your docker or docker-machine ip ( as usual )

## Logs

You find the logs under ```/var/lib/apacheds-2.0.0_M20/default/log/apacheds.log```
## Build

```
cd make
make build
```