FROM ruby:2.3.1
MAINTAINER Zammad.org <info@zammad.org>
ARG BUILD_DATE

ENV DEBIAN_FRONTEND=noninteractive
ENV ZAMMAD_DIR /opt/zammad
ENV JAVA_DEBIAN_VERSION "8u121-b13-1~bpo8+1"
ENV CA_CERTIFICATES_JAVA_VERSION "20161107~bpo8+1"
#ENV ZAMMAD_ES_URL elasticsearch
#ENV ZAMMAD_DB_HOST mariadb
#ENV ZAMMAD_DB zammad
#ENV ZAMMAD_DB_USER zammad
#ENV RAILS_ENV production
#ENV RAILS_SERVER puma
#ENV GIT_URL https://github.com/zammad/zammad.git
#ENV GIT_BRANCH develop
#ENV ES_SKIP_SET_KERNEL_PARAMETERS true

LABEL org.label-schema.build-date="$BUILD_DATE" \
      org.label-schema.name="Zammad" \
      org.label-schema.license="AGPL-3.0" \
      org.label-schema.description="Zammad Docker container for easy testing" \
      org.label-schema.url="https://zammad.org" \
      org.label-schema.vcs-url="https://github.com/zammad/zammad" \
      org.label-schema.vcs-type="Git" \
      org.label-schema.vendor="Zammad" \
      org.label-schema.schema-version="1.2"
      # \
      #org.label-schema.docker.cmd="docker run -ti -p 80:80 zammad/zammad"

# Expose ports
EXPOSE 80

# adding backport (openjdk)
RUN echo "deb http://ftp.de.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list

# fixing service start
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# install zammad
COPY scripts/install-zammad.sh /tmp
RUN chmod +x /tmp/install-zammad.sh;/bin/bash -l -c /tmp/install-zammad.sh

# cleanup
RUN rm -rf /var/lib/apt/lists/* preseed.txt
# install dependencies
RUN apt-get update && apt-get --no-install-recommends -y install apt-transport-https libterm-readline-perl-perl locales mc net-tools nginx openjdk-8-jre openjdk-8-jre-headless="$JAVA_DEBIAN_VERSION" ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION"

# install postfix
RUN echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt
RUN debconf-set-selections preseed.txt
RUN apt-get --no-install-recommends install -q -y postfix

# docker init
COPY scripts/docker-entrypoint.sh /
RUN chown zammad:zammad /docker-entrypoint.sh;chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["zammad"]
