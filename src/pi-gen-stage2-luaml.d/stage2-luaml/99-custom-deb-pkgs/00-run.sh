#!/bin/bash -e

for deb in files/*.deb; do
	log "    INFO -- Installing $deb on target ..."
	cp -vf $deb "${ROOTFS_DIR}/tmp/"
	on_chroot << EOF
		set -x
		dpkg -i /tmp/$(basename "${deb}")
EOF
done

#
# TODO: Fix this hack -- it assumes the package is installed in the previous step ... >:-/
#
log "    INFO -- Enabling set-distinct-hostname.service on target ..."
on_chroot << EOF
set -x
systemctl enable set-distinct-hostname.service
EOF


log "    INFO -- HOSTNAME_PREFIX is \"${HOSTNAME_PREFIX}\""
if [[ -n "${HOSTNAME_PREFIX}" ]]; then
  set -x
  sed -i \
    -e 's/^HOSTNAME_PREFIX=.*/HOSTNAME_PREFIX="'${HOSTNAME_PREFIX}'"/' \
    "${ROOTFS_DIR}/etc/default/set-distinct-hostname-service"
  set +x
fi
