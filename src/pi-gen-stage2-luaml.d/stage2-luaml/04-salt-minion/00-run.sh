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
if ! (dpkg-query --show salt-minion); then 
	curl -sLf http://bootstrap.saltstack.com | \
		/bin/sh -s -- -X -F -A $SALT_MASTER $SALTSTACK_VERSION
else
	echo "salt-minion already installed (skipping this step)"
fi
set +x
EOF

echo "# ------------------------------------------------------------ #"
echo "# Cleaning up ..."
echo "# ------------------------------------------------------------ #"

on_chroot << EOF
set -x
rm -fv /etc/salt/minion_id
rm -fv /etc/salt/pki/minion/minion.p*
if ! $SALT_ENABLED; then
	update-rc.d salt-minion disable || \
	  find /etc/systemd/system -name salt-minion.service -type l -delete
else
    echo "Leaving salt-minion enabled."
fi
set +x
EOF

echo "# ------------------------------------------------------------ #"
echo "# end of saltstack installation script"
echo "# ------------------------------------------------------------ #"

