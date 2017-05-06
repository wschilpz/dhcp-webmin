#!/bin/bash
set -e

ROOT_PASSWORD=${ROOT_PASSWORD:-password}
WEBMIN_ENABLED=${WEBMIN_ENABLED:-true}

DHCP_DATA_DIR=${DATA_DIR}/dhcp
WEBMIN_DATA_DIR=${DATA_DIR}/webmin

create_dhcp_data_dir() {
  mkdir -p ${DHCP_DATA_DIR}

  # populate default bind configuration if it does not exist
  if [ ! -d ${DHCP_DATA_DIR}/etc ]; then
    mv /etc/dhcp ${DHCP_DATA_DIR}/etc
  fi
  rm -rf /etc/dhcp
  ln -sf ${DHCP_DATA_DIR}/etc /etc/dhcp
  chmod -R 0775 ${DHCP_DATA_DIR}
  chown -R ${DHCP_USER}:${DHCP_USER} ${DHCP_DATA_DIR}

  if [ ! -d ${DHCP_DATA_DIR}/lib ]; then
    mkdir -p ${DHCP_DATA_DIR}/lib
    chown ${DHCP_USER}:${DHCP_USER} ${DHCP_DATA_DIR}/lib
  fi
  rm -rf /var/lib/dhcpd
  ln -sf ${BIND_DATA_DIR}/lib /var/lib/dhcpd

   [ -e "${BIND_DATA_DIR}/lib/dhcpd.leases" ] || touch "${BIND_DATA_DIR}/lib/dhcpd.leases"
    chown dhcpd:dhcpd "${BIND_DATA_DIR}/lib/dhcpd.leases"
    if [ -e "${BIND_DATA_DIR}/lib/dhcpd.leases~" ]; then
        chown dhcpd:dhcpd "${BIND_DATA_DIR}/lib/dhcpd.leases~"
    fi
}

create_webmin_data_dir() {
  mkdir -p ${WEBMIN_DATA_DIR}
  chmod -R 0755 ${WEBMIN_DATA_DIR}
  chown -R root:root ${WEBMIN_DATA_DIR}

  # populate the default webmin configuration if it does not exist
  if [ ! -d ${WEBMIN_DATA_DIR}/etc ]; then
    mv /etc/webmin ${WEBMIN_DATA_DIR}/etc
  fi
  rm -rf /etc/webmin
  ln -sf ${WEBMIN_DATA_DIR}/etc /etc/webmin
}

set_root_passwd() {
    echo "Setting root password to $ROOT_PASSWORD"
  echo "root:$ROOT_PASSWORD" | chpasswd
  echo "Password changed"
}

create_dhcp_data_dir

# allow arguments to be passed to named
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == dhcpd || ${1} == $(which dhcpd) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# default behaviour is to launch named
if [[ -z ${1} ]]; then
  if [ "${WEBMIN_ENABLED}" == "true" ]; then
    create_webmin_data_dir
    set_root_passwd
    echo "Starting webmin..."
    /etc/init.d/webmin start
    #systemctl start webmin
  fi

  echo "Starting dhcp..."
  exec $(which dhcpd) -f -d --no-pid -user ${DHCP_USER}
else
  exec "$@"
fi