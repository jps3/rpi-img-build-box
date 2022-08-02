#!/bin/bash -ex

install -v -d "${ROOTFS_DIR}/opt/3dprinteros-client"
install -v -m 644 "files/${SORETNIRPD3_ZIP}" "${ROOTFS_DIR}/tmp/"

on_chroot <<EOF
  unzip -o -d "/opt/3dprinteros-client/" "/tmp/${SORETNIRPD3_ZIP}"
EOF

install -v -o root -g root -m 644 "files/3dprinteros.service" "${ROOTFS_DIR}/etc/systemd/system/"

on_chroot <<EOF
systemctl daemon-reload
if "${SALT_ENABLED:-false}"; then
  systemctl enable salt-minion
else
  systemctl disable salt-minion
fi
EOF

