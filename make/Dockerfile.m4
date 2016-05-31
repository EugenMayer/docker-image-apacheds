FROM centos:7

MAINTAINER "Greg Gigon @ https://github.com/greggigon"

# http://mirror.netcologne.de/apache.org//directory/apacheds/dist/2.0.0-M21/apacheds-2.0.0-M21-x86_64.rpm
RUN yum -y update && yum -y install openssl java-1.7.0-openjdk openldap-clients && curl -s http://mirror.netcologne.de/apache.org//directory/apacheds/dist/2.0.0-M21/apacheds-2.0.0-M21-x86_64.rpm -o /tmp/apacheds.rpm \
	&& yum -y localinstall /tmp/apacheds.rpm && rm -rf /tmp/apacheds.rpm && mkdir -p /bootstrap \
	&& ln -s /var/lib/apacheds-2.0.0_M21/default/partitions /data \
	&& chown -R apacheds.apacheds /data && chown -R apacheds.apacheds /var/lib/apacheds-2.0.0_M21/default/partitions

ADD build/apacheds.sh /usr/local/bin/
ADD build/config.ldif /tmp/config.tpl.ldif
ADD build/create_config.sh /usr/local/bin/
ADD build/create_keystore.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/apacheds.sh \
  && chmod +x /usr/local/bin/create_keystore.sh \
  && chmod +x /usr/local/bin/create_config.sh

VOLUME /data
VOLUME /bootstrap

ENTRYPOINT /usr/local/bin/apacheds.sh
EXPOSE 10389
