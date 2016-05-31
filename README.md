## WAT

Offers a build for apacheds forked from [greggigon great work](https://github.com/greggigon/apacheds) to add extensible configuration using ENV
This work is specifically created to be enable configuration in a rancher catalog like this [catalog](https://github.com/EugenMayer/kontextwork-catalog/tree/master/templates/apacheds)
but can be used for every environment.

You can easily configure the server SASL/Kerberos and the default partition using ENV, see the test/docker-compose.yml file for further informations or even this (file with its descriptions)[https://github.com/EugenMayer/kontextwork-catalog/tree/master/templates/apacheds/0/rancher-compose.yml]
Docker images will be published on [hub.docker.io](https://hub.docker.com/r/eugenmayer/apacheds/)

## Releases

For now, only planed to be published on [hub.docker.io](https://hub.docker.com/r/eugenmayer/apacheds/)

## Test

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