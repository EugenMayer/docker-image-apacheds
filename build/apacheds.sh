#!/bin/bash
# derived from the work here https://github.com/greggigon/apacheds thank you!

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


# if certificates are available, pack them into a keystore, since thats what apacheds understands
if [ -f /certs/fullchain.pem -a -f /certs/privkey.pem -a ! -f $DS_KEYSTORE_PATH ]; then
	echo "Packing certificates into keychain format for apacheds and saving it to $DS_KEYSTORE_PATH"
	/usr/local/bin/create_keystore.sh
fi

# if the user provided a configuration, take it
if [ -f /bootstrap/config.ldif ] && [ ! -f /bootstrap/.config_imported ]; then
	echo "Using config file from /bootstrap/config.ldif"
	rm -rf ${APACHEDS_INSTANCE}/conf/config.ldif
	cp /bootstrap/config.ldif ${APACHEDS_INSTANCE}/conf/
	chown apacheds.apacheds ${APACHEDS_INSTANCE}/conf/config.ldif
	touch /bootstrap/.config_imported
else
	if [ ! -f /bootstrap/.config_imported ]; then
	   # otherwise use our template and fill in all the values from the ENV
	   echo "Generating config from template"
	   /usr/local/bin/create_config.sh
	   rm -fr ${APACHEDS_INSTANCE}/conf/config.ldif_migrated
	   rm -rf ${APACHEDS_INSTANCE}/conf/config.ldif
	   rm -rf ${APACHEDS_INSTANCE}/conf/ou=config
	   rm -fr ${APACHEDS_INSTANCE}/conf/'ou=config.ldif'
	   cp /tmp/config.ldif ${APACHEDS_INSTANCE}/conf/
	   chown apacheds.apacheds ${APACHEDS_INSTANCE}/conf/config.ldif
	   rm -fr /tmp/config.ldif
	   chown apacheds.apacheds -R ${APACHEDS_INSTANCE}/partitions
	   touch /bootstrap/.config_imported
   else
	   echo "not touching configuration, since it has been imported before. Remove /bootstrap/.config_imported to retry this"
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

if [ -n "${BOOTSTRAP_FILE}" ]; then
	echo "Bootstraping Apache DS with Data from ${BOOTSTRAP_FILE}"
	ldapmodify -h localhost -p 10389 -D 'uid=admin,ou=system' -w secret -f $BOOTSTRAP_FILE
fi

trap "echo 'Stoping Apache DS';/opt/apacheds-$VERSION/bin/apacheds stop default;exit 0" SIGTERM SIGKILL

while true
do
  tail -f /dev/null & wait ${!}
done