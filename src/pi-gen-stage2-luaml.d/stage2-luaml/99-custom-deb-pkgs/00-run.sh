#!/bin/bash -x

cp -vf files/*.deb "${ROOTFS_DIR}/tmp/"

on_chroot << EOF
cd /tmp/
pwd
ls -1 *.deb
for deb in *.deb; do
	dpkg -i \$deb
done
EOF

on_chroot << EOF
set -e
cd /etc/systemd/system/
[[ ! -d network.target.wants ]] && mkdir -m 755 network.target.wants
cd network.target.wants
ln -svf ../set-distinct-hostname.service
EOF

on_chroot << EOF
sed -i -e 's/^HOSTNAME_PREFIX=.*/HOSTNAME_PREFIX="${HOSTNAME_PREFIX}"/' /etc/default/set-distinct-hostname-service
EOF
