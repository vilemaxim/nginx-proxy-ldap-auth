FROM nginx:1.9.6
#All the heavy lifting was done by Jason Wilder mail@jasonwilder.com
# I only modified a few lines
MAINTAINER Jeffrey Brite jeff@c4tech.com

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN echo "deb-src http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

# Install wget and install/updates certificates dpkg git (dpkg and git is needed for nginx ldap)
RUN apt-get update
RUN apt-get install -y -q --no-install-recommends ca-certificates wget dpkg-dev git  libldap2-dev

RUN git clone https://github.com/kvspb/nginx-auth-ldap.git
RUN apt-get source nginx=1.9.6-1~jessie
RUN apt-get build-dep -y -q nginx
RUN sed -i 's/with-file-aio/& \\\n              \-\-add-module=\/nginx-auth-ldap\//g' ./nginx-1.9.6/debian/rules

RUN echo changeing
RUN cd ./nginx-1.9.6/ &&  dpkg-buildpackage -b
RUN dpkg -i ./nginx_1.9.6-1~jessie_amd64.deb

#RUN rm -R ./nginx-1.9.6/ && rm -R ./nginx-auth-ldap
#RUN rm ./nginx_1.9.6-1~jessie_amd64.deb

#RUN apt-get -y upgrade
# Apt clean up
#RUN apt-get remove --purge -y dpkg-dev
#RUN apt-get remove -y git git-man krb5-locales less libbsd0 libcurl3-gnutls libedit2 liberror-perl \
#                   libexpat1 libgssapi-krb5-2 libk5crypto3 libkeyutils1 libkrb5-3 \
#                   libkrb5support0 libldap-2.4-2 libpopt0 librtmp1 libsasl2-2 libsasl2-modules \
#                   libsasl2-modules-db libssh2-1 libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 \
#                   libxext6 libxmuu1 openssh-client rsync xauth
RUN apt-get clean
RUN rm -r /var/lib/apt/lists/*
# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf

# Install Forego
RUN wget -P /usr/local/bin https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego \
 && chmod u+x /usr/local/bin/forego

ENV DOCKER_GEN_VERSION 0.4.2

RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz$
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

COPY . /app/
WORKDIR /app/

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs"]
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
