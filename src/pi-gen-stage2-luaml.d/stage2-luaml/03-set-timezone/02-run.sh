#!/bin/bash -e

# shellcheck source=/home/vagrant/build/pi-gen/config-luaml
source "${BASE_DIR}"/config-luaml

export TIMEZONE


if [[ ! -z "${TIMEZONE}" ]]; then
    echo "${TIMEZONE}" > "${ROOTFS_DIR}/etc/timezone"
    rm "${ROOTFS_DIR}/etc/localtime"

    on_chroot << EOF
    dpkg-reconfigure -f noninteractive tzdata
EOF
else
    echo "# WARN # $TIMEZONE not specified. Leaving at default set in stage2."
fi
