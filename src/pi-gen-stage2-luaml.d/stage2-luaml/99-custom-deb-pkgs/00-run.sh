#!/bin/bash -e

cp -vf files/*.deb "${ROOTFS_DIR}/tmp/"

echo "# ------------------------------------------------------------ #"
echo "# INFO"
echo "#"
echo "# $0"
echo "#"
echo "# ------------------------------------------------------------ #"

on_chroot << EOF
set -x
cd /tmp/
pwd
ls -1 *.deb
for deb in *.deb; do
  dpkg -i \$deb
done
set +x
EOF


on_chroot << EOF
set -x
systemctl enable set-distinct-hostname.service
set +x
EOF


echo "# ------------------------------------------------------------ #"
echo "# INFO"
echo "#"
echo "# HOSTNAME_PREFIX    : '${HOSTNAME_PREFIX}'"
echo "#"
echo "# ------------------------------------------------------------ #"

if [[ -n "${HOSTNAME_PREFIX}" ]]; then
  set -x
  sed -i \
    -e 's/^HOSTNAME_PREFIX=.*/HOSTNAME_PREFIX="'${HOSTNAME_PREFIX}'"/' \
    "${ROOTFS_DIR}/etc/default/set-distinct-hostname-service"
  set +x
fi

echo "# ------------------------------------------------------------ #"
echo "#  END"
echo "# ------------------------------------------------------------ #"
