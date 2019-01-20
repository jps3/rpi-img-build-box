#!/bin/bash -e

PATH=/bin:/sbin:/usr/bin:/usr/sbin

DEFAULT_INTERFACE="eth0"

SYS_PATH="/sys/class/net/${DEFAULT_INTERFACE}/address"
if [[ -s "${SYS_PATH}" ]]; then
	DEFAULT_INTERFACE_MAC="$(<$SYS_PATH)"
else
	echo "$0: $SYS_PATH does not exist." | systemd-cat
	exit -1
fi

if [[ -z "$DEFAULT_INTERFACE_MAC" ]]; then
	echo "$0: DEFAULT_INTERFACE_MAC is empty." | systemd-cat
	exit -2
fi

MAC_STUB="$(echo $DEFAULT_INTERFACE_MAC | cut -d: -f4- | tr -d : | tr 'a-z' 'A-Z')"
NEW_HOSTNAME="${HOSTNAME_PREFIX:-pi}-${MAC_STUB}"


#
# Simple check that results in exiting with an error if any spaces
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

