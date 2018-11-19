#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin

set -e
set -E

NETWORK_IFACE_MAC_NIC="$(cat /sys/class/net/${NETWORK_IFACE}/address | cut -d: -f4- | tr -d : | tr 'a-z' 'A-Z')"
NEW_HOSTNAME="${HOSTNAME_PREFIX}-${NETWORK_IFACE_MAC_NIC}"

#
# Simple check that results in existing with an error if any spaces
# are found in $NEW_HOSTNAME
#
echo "$NEW_HOSTNAME" | grep -v -q '[[:space:]]'

#
# Set the new hostname
#
echo $NEW_HOSTNAME > /proc/sys/kernel/hostname
echo $NEW_HOSTNAME > /etc/hostname
/bin/hostname -F /etc/hostname

#
# Update /etc/hosts 127.0.1.1
#
sed -i -e '/^127\.0\.1\.1/ s/raspberrypi/'${NEW_HOSTNAME}'/' /etc/hosts

set +E
set +e

exit 0

