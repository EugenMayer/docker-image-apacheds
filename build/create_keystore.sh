#!/bin/bash

# uses the private key and certicate and adds them into a keychain which will be used by apacheds
cd /certs
openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out temp.p12 -name "$DS_HOST" -passout pass:changeit
keytool -importkeystore -deststorepass changeit -destkeypass changeit -destkeystore $DS_KEYSTORE_PATH -srckeystore temp.p12 -srcstoretype PKCS12 -alias "$DS_HOST" -srcstorepass "changeit"
rm temp.p12
chown apacheds.apacheds $DS_KEYSTORE_PATH
