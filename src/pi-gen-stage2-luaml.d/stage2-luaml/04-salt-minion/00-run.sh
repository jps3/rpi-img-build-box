#!/bin/bash -e

echo "# ------------------------------------------------------------ #"
echo "# INFO"
echo "#"
echo "# SALT_MASTER        : '${SALT_MASTER}'"
echo "# SALTSTACK_VERSION  : '${SALTSTACK_VERSION}'"
echo "# SALT_ENABLED       : '${SALT_ENABLED}'"
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
  systemctl disable salt-minion || \
    find /etc/systemd/system -name salt-minion.service -type l -delete
else
  echo "Ensuring salt-minion service is enabled ..."
  systemctl enable salt-minion
fi
set +x
EOF

set +e
on_chroot << EOF
set -x
service salt-minion stop
pkill -U root -f /usr/bin/salt-minion
set +x
EOF
set -e

echo "# ------------------------------------------------------------ #"
echo "# end of saltstack installation script"
echo "# ------------------------------------------------------------ #"

