#!/bin/bash -e

if [[ ! -z "${TIMEZONE}" ]]; then
    echo "${TIMEZONE}" > "${ROOTFS_DIR}/etc/timezone"
    rm "${ROOTFS_DIR}/etc/localtime"

    on_chroot << EOF
    dpkg-reconfigure -f noninteractive tzdata
EOF
else
    log "    WARN -- $TIMEZONE not specified. Leaving at default set in stage2."
fi
