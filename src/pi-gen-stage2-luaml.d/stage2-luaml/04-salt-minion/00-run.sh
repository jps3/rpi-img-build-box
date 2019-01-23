#!/bin/bash -e

# shellcheck source=/home/vagrant/build/pi-gen/config-luaml
source "${BASE_DIR}"/config-luaml

export SALTSTACK_VERSION
export SALT_MASTER="${SALT_MASTER:-salt}"


echo "# ------------------------------------------------------------ #"
echo "# INFO"
echo "#"
echo "# SALT_MASTER        : '${SALT_MASTER}'"
echo "# SALTSTACK_VERSION  : '${SALTSTACK_VERSION}'"
echo "#"
echo "# ------------------------------------------------------------ #"

on_chroot << EOF
set -x
curl -sLf http://bootstrap.saltstack.com | \
	/bin/sh -s -- -X -F -A $SALT_MASTER $SALTSTACK_VERSION
set +x
EOF

echo "# ------------------------------------------------------------ #"
echo "# Cleaning up ..."
echo "# ------------------------------------------------------------ #"

on_chroot << EOF

set -x
#pkill -f salt-minion
rm -fv /etc/salt/minion_id
rm -fv /etc/salt/pki/minion/minion.p*
update-rc.d salt-minion disable || \
  find /etc/systemd/system -name salt-minion.service -type l -delete
set +x

EOF

echo "# ------------------------------------------------------------ #"
echo "# end of saltstack installation script"
echo "# ------------------------------------------------------------ #"

