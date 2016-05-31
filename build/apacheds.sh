#!/bin/bash
VERSION=2.0.0_M21
APACHEDS_INSTANCE=/var/lib/apacheds-$VERSION/default

function wait_for_ldap {
	echo "Waiting for LDAP to be available "
	c=0

    ldapsearch -h localhost -p 10389 -D 'uid=admin,ou=system' -w secret ou=system;

    while [ $? -ne 0 ]; do
        echo "LDAP not up yet... retrying... ($c/20)"
        sleep 4

 		if [ $c -eq 20 ]; then
 			echo "TROUBLE!!! After [${c}] retries LDAP is still dead :("
 			exit 2
 		fi
 		c=$((c+1))

    	ldapsearch -h localhost -p 10389 -D 'uid=admin,ou=system' -w secret ou=system;
    done
}

if [ -f /bootstrap/config.ldif ] && [ ! -f ${APACHEDS_INSTANCE}/conf/config.ldif_migrated ]; then
	echo "Using config file from /bootstrap/config.ldif"
	rm -rf ${APACHEDS_INSTANCE}/conf/config.ldif

	cp /bootstrap/config.ldif ${APACHEDS_INSTANCE}/conf/
	chown apacheds.apacheds ${APACHEDS_INSTANCE}/conf/config.ldif
else
   echo "Generating config from template"
   /usr/local/bin/create_config.sh
   rm -rf ${APACHEDS_INSTANCE}/conf/config.ldif
   rm -fr ${APACHEDS_INSTANCE}/conf/'ou=config.ldif'
   cp /tmp/config.ldif ${APACHEDS_INSTANCE}/conf/
   chown apacheds.apacheds ${APACHEDS_INSTANCE}/conf/config.ldif
   #rm -fr /tmp/config.ldif
fi

if [ -f /certs/fullchain.pem -a -f /certs/privkey.pem ]; then
	/usr/local/bin/create_keystore.sh
fi

if [ -d /bootstrap/schema ]; then
	echo "Using schema from /bootstrap/schema directory"
	rm -rf ${APACHEDS_INSTANCE}/partitions/schema

	cp -R /bootstrap/schema/ ${APACHEDS_INSTANCE}/partitions/
	chown -R apacheds.apacheds ${APACHEDS_INSTANCE}/partitions/
fi

# There should be no correct scenario in which the pid file is present at container start
rm -f ${APACHEDS_INSTANCE}/run/apacheds-default.pid

/opt/apacheds-$VERSION/bin/apacheds start default

wait_for_ldap


if [ -n "${BOOTSTRAP_FILE}" ]; then
	echo "Bootstraping Apache DS with Data from ${BOOTSTRAP_FILE}"

	ldapmodify -h localhost -p 10389 -D 'uid=admin,ou=system' -w secret -f $BOOTSTRAP_FILE
fi

trap "echo 'Stoping Apache DS';/opt/apacheds-$VERSION/bin/apacheds stop default;exit 0" SIGTERM SIGKILL

while true
do
  tail -f /dev/null & wait ${!}
done