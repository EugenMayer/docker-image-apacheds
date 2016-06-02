#!/bin/bash
# derived from the work here https://github.com/greggigon/apacheds thank you!
VERSION=2.0.0_M21
APACHEDS_INSTANCE=/var/lib/apacheds-$VERSION/default
CONFIG_SEMAPHORON=/bootstrap/config_imported
CUSTOM_CONFIG=/bootstrap/config.ldif
function wait_for_ldap {
	echo "Waiting for LDAP to be available "
	c=0

    netstat -na|grep LISTEN|grep 10389

    while [ $? -ne 0 ]; do
        echo "LDAP not up yet... retrying... ($c/20)"
        sleep 4

 		if [ $c -eq 20 ]; then
 			echo "TROUBLE!!! After [${c}] retries LDAP is still dead :("
 			exit 2
 		fi
 		c=$((c+1))

    	netstat -na|grep LISTEN|grep 10389
    done
    echo "ApacheDS up and running"
}

function cleanup_config {
	rm -rf ${APACHEDS_INSTANCE}/conf/config.ldif
	rm -fr ${APACHEDS_INSTANCE}/conf/config.ldif_migrated
	rm -rf ${APACHEDS_INSTANCE}/conf/ou=config
	rm -fr ${APACHEDS_INSTANCE}/conf/'ou=config.ldif'
}

# if certificates are available, pack them into a keystore, since thats what apacheds understands
if [ -f /certs/fullchain.pem -a -f /certs/privkey.pem -a ! -f $DS_KEYSTORE_PATH ]; then
	echo "Packing certificates into keychain format for apacheds and saving it to $DS_KEYSTORE_PATH"
	/usr/local/bin/create_keystore.sh
else
	if [ ! -f /certs/privkey.pem -o ! -f /certs/fullchain.pem ]; then
	    echo "No certificates found, not configuring TLS"
	fi
fi

# if the user provided a configuration, take it
if [ -f $CUSTOM_CONFIG ] && [ ! -f $CONFIG_SEMAPHORON ]; then
	echo "Using config file from $CUSTOM_CONFIG"
	cleanup_config
	cp $CUSTOM_CONFIG ${APACHEDS_INSTANCE}/conf/config.ldif
	chown apacheds.apacheds ${APACHEDS_INSTANCE}/conf/config.ldif
	chown apacheds.apacheds -R ${APACHEDS_INSTANCE}/partitions
	cp /local_conf/wrapper-instance.conf ${APACHEDS_INSTANCE}/conf/wrapper-instance.conf
	touch $CONFIG_SEMAPHORON
else
	if [ ! -f $CONFIG_SEMAPHORON ]; then
	   # otherwise use our template and fill in all the values from the ENV
	   echo "Generating config from template"
	   cleanup_config
	   /usr/local/bin/create_config.sh
	   cp /tmp/config.ldif ${APACHEDS_INSTANCE}/conf/

	   # no persist our generated config for reimports
	   mv /tmp/config.ldif /bootstrap/config.ldif

	   chown apacheds.apacheds ${APACHEDS_INSTANCE}/conf/config.ldif
	   chown apacheds.apacheds -R ${APACHEDS_INSTANCE}/partitions
	   cp /local_conf/wrapper-instance.conf ${APACHEDS_INSTANCE}/conf/wrapper-instance.conf
	   touch $CONFIG_SEMAPHORON
   else
   	   if [ ! -f ${APACHEDS_INSTANCE}/conf/wrapper-instance.conf ]; then
   	       cp /local_conf/wrapper-instance.conf ${APACHEDS_INSTANCE}/conf/wrapper-instance.conf
   	   fi
	   echo "Not touching configuration, since it has been imported before. Remove $CONFIG_SEMAPHORON to re-import the configuration (replacing the current)"
   fi
fi

# custom schema available, use it
if [ -d /bootstrap/schema ]; then
	echo "Using schema from /bootstrap/schema directory"
	rm -rf ${APACHEDS_INSTANCE}/partitions/schema

	cp -R /bootstrap/schema/ ${APACHEDS_INSTANCE}/partitions/
	chown -R apacheds.apacheds ${APACHEDS_INSTANCE}/partitions/
fi

# There should be no correct scenario in which the pid file is present at container start
rm -f ${APACHEDS_INSTANCE}/run/apacheds-default.pid

/opt/apacheds-$VERSION/bin/apacheds start default
chown apacheds.apacheds -R ${APACHEDS_INSTANCE}/partitions

wait_for_ldap

trap "echo 'Stoping Apache DS';/opt/apacheds-$VERSION/bin/apacheds stop default;exit 0" SIGTERM SIGKILL

while true
do
  tail -f /dev/null & wait ${!}
done