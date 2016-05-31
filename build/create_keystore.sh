#!/bin/bash

DOMAIN='auth.kw.kontextwork.com'
openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out temp.p12 -name "$DOMAIN" -passout pass:changeit
keytool -importkeystore -deststorepass changeit -destkeypass changeit -destkeystore apacheds.keystore -srckeystore temp.p12 -srcstoretype PKCS12 -alias "$DOMAIN" -srcstorepass "changeit"
rm temp.p12
