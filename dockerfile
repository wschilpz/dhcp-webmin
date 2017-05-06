FROM library/fedora
MAINTAINER warren.schilpzand@gmail.com

ENV DHCP_USER=dhcpd \
    WEBMIN_VERSION=1.8\
    DATA_DIR=/data \
    container=docker

RUN dnf -y install systemd \
    && dnf -y install wget \
    && dnf -y install which \
    && dnf -y install perl perl-Net-SSLeay openssl perl-IO-Tty 'perl(Time::Local)' \
    && wget http://www.webmin.com/jcameron-key.asc \
    && wget  http://www.webmin.com/download/rpm/webmin-current.rpm \
    && rpm --import jcameron-key.asc \
    && rpm -Uvh webmin-*.rpm \
    && dnf -y install dhcp \
    && (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done) \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/*

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh

EXPOSE 67/udp 10000/tcp
VOLUME ["${DATA_DIR}"]
VOLUME [ “/sys/fs/cgroup” ]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/dhcpd"]



