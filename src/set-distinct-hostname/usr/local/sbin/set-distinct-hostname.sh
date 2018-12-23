#!/bin/bash -e

PATH=/bin:/sbin:/usr/bin:/usr/sbin

DEFAULT_INTERFACE="$(route | awk '$1=="default" { print $NF }')"
DEFAULT_INTERFACE_MAC="$(cat /sys/class/net/${DEFAULT_INTERFACE}/address)"
MAC_STUB="$(echo $DEFAULT_INTERFACE_MAC | cut -d: -f4- | tr -d : | tr 'a-z' 'A-Z')"
NEW_HOSTNAME="${HOSTNAME_PREFIX:-pi}-${MAC_STUB}"


#
# Simple check that results in existing with an error if any spaces
# are found in $NEW_HOSTNAME
#
echo "$NEW_HOSTNAME" | grep -v -q '[[:space:]]'


#
# Set the new hostname
#
hostnamectl set-hostname $NEW_HOSTNAME


#
# Update /etc/hosts 127.0.1.1
#
sed -i -e '/^127\.0\.1\.1/ s/raspberrypi/'${NEW_HOSTNAME}'/' /etc/hosts


exit 0

