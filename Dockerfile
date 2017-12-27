FROM debian:stretch-slim

MAINTAINER Alexey Zhokhov <alexey@zhokhov.com>

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r ftpgroup && useradd -g ftpgroup -d /home/ftpusers -s /dev/null ftpuser

ARG S3FS_VERSION=v1.83

ENV PUBLICHOST localhost

ENV DEBIAN_FRONTEND noninteractive

# Runtime requirements
RUN set -ex \
    && mkdir -p /var/cache/apt/archives \
    && touch /var/cache/apt/archives/lock \
    && apt-get clean \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
               fuse \
               libfuse2 \
               libcurl3-gnutls \
               libxml2 \
               libssl1.1 \
               libcurl3 \
               ca-certificates \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/* /var/cache/apt/* /tmp/*

# Build s3fs
RUN set -ex \
    && BUILD_REQS="build-essential git libfuse-dev libcurl4-openssl-dev libxml2-dev mime-support automake libtool pkg-config libssl-dev pkg-config libssl-dev git" \
    && apt-get clean \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends $BUILD_REQS \
    && cd /tmp \
    && git clone --branch $S3FS_VERSION --depth 1 https://github.com/s3fs-fuse/s3fs-fuse.git \
    && cd s3fs-fuse \
    && echo "/usr/local/lib" > /etc/ld.so.conf.d/libc.conf \
	&& export MAKEFLAGS="-j$[$(nproc) + 1]" \
	&& export SRC=/usr/local \
	&& export PKG_CONFIG_PATH=${SRC}/lib/pkgconfig \
    && ./autogen.sh \
	&& ./configure \
	&& make \
	&& make install \
	&& apt-get -y remove $BUILD_REQS \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/* /var/cache/apt/* /tmp/*

# Build pure-ftpd
RUN set -ex \
    && echo "deb http://http.debian.net/debian stretch main\n\
deb-src http://http.debian.net/debian stretch main\n\
deb http://http.debian.net/debian stretch-updates main\n\
deb-src http://http.debian.net/debian stretch-updates main\n\
deb http://security.debian.org stretch/updates main\n\
deb-src http://security.debian.org stretch/updates main\n\
" > /etc/apt/sources.list \
    && BUILD_REQS="dpkg-dev debhelper" \
    && apt-get clean \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get -y --fix-missing install $BUILD_REQS \
    && apt-get -y build-dep pure-ftpd \
	  && mkdir /tmp/pure-ftpd \
	  && cd /tmp/pure-ftpd \
	  && apt-get source pure-ftpd \
	  && cd pure-ftpd-* \
	  && ./configure --with-tls \
	  && sed -i '/^optflags=/ s/$/ --without-capabilities/g' ./debian/rules \
   && dpkg-buildpackage -b -uc \
	  && dpkg -i /tmp/pure-ftpd/pure-ftpd-common*.deb \
	  && apt-get -y install openbsd-inetd \
	  && dpkg -i /tmp/pure-ftpd/pure-ftpd_*.deb \
    && apt-mark hold pure-ftpd pure-ftpd-common \
    && apt-get install -y rsyslog \
    && echo "" >> /etc/rsyslog.conf \
    && echo "#PureFTP Custom Logging" >> /etc/rsyslog.conf \
    && echo "ftp.* /var/log/pure-ftpd/pureftpd.log" >> /etc/rsyslog.conf \
    && echo "Updated /etc/rsyslog.conf with /var/log/pure-ftpd/pureftpd.log" \
    && apt-get -y remove $BUILD_REQS \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/* /var/cache/apt/* /tmp/*

# config
RUN echo "no" > /etc/pure-ftpd/conf/Daemonize
RUN echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone
RUN echo "yes" > /etc/pure-ftpd/conf/IPV4Only
RUN echo 'yes' > /etc/pure-ftpd/conf/VerboseLog

RUN echo "user_allow_other" >> /etc/fuse.conf

# View version
RUN /usr/local/bin/s3fs --version

VOLUME ["/home/ftpusers", "/etc/pure-ftpd/passwd"]


EXPOSE 21 30000-30009

COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

