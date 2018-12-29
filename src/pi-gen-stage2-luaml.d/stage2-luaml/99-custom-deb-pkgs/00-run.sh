#!/bin/bash 

cp -vf files/*.deb "${ROOTFS_DIR}/tmp/"

on_chroot << EOF
cd /tmp/
pwd
ls -1 *.deb
for deb in *.deb; do
	dpkg -i \$deb
done
EOF

