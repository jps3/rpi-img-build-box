#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin

hostname_prefix=""
net_iface="eth0"
net_iface_mac_nic="$(cat /sys/class/net/${net_iface}/address | cut -d: -f4- | tr -d : | tr 'a-z' 'A-Z')"

new_hostname="${hostname_prefix}-${net_iface_mac_nic}"

echo $new_hostname > /proc/sys/kernel/hostname
echo $new_hostname > /etc/hostname
/bin/hostname -F /etc/hostname

if [[ ! -e /etc/salt/minion_id ]]; then
	echo $new_hostname > /etc/salt/minion_id
fi
