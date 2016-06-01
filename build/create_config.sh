#!/bin/bash

SRC=/tmp/config.tpl.ldif
DEST=/tmp/config.ldif
cp $SRC $DEST

sed -e "s/TPL-S-HOST/${DS_SASL_HOST}/" -i $DEST
sed -e "s/TPL-S-REALM/${DS_SASL_REALM}/" -i $DEST
sed -e "s/TPL-S-DOM/${DS_SASL_DOMAIN}/" -i $DEST
sed -e "s/dc=saslbasedn,dc=com/${DS_SASL_BASEDN}/" -i $DEST
sed -e "s/TPLP1ID/${DS_PARTITION1_ID}/" -i $DEST
sed -e "s/dc=partition1,dc=com/${DS_PARTITION1_SUFFIX}/" -i $DEST
sed -e "s/TPL-KRB-R/${DS_KRB_REALM}/" -i $DEST
sed -e "s/ou=users,dc=kerberosrealm,dc=com/${DS_KRB_BASEDN}/" -i $DEST
if [ -f $DS_KEYSTORE_PATH ]; then
	sed -e "s|TPL-KS-PATH|${DS_KEYSTORE_PATH}|" -i $DEST
else
	echo "WARNING: defined a keystore '$DS_KEYSTORE_PATH', but the file does not exist. Skipping configuration"
fi
