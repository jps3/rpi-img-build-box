#!/bin/bash -ex

install -v -d "${ROOTFS_DIR}/opt/3dprinteros-client"
unzip -o -d "${ROOTFS_DIR}/opt/3dprinteros-client/" "files/3DPrinterOS_Client_6.2.3.165_stable.zip"

install -v -o root -g root -m 644 "files/3dprinteros.service" "${ROOTFS_DIR}/etc/systemd/system/"

on_chroot <<EOF
systemctl daemon-reload
if "${SALT_ENABLED:-false}"; then
  systemctl enable salt-minion
else
  systemctl disable salt-minion
fi
EOF

