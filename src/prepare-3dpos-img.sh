#!/usr/bin/env bash

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

set -e -E    # Same as: set -o errexit -o errtrace

################################################################################
#
# vars
#
################################################################################

IMG_ORIG="${1}"
IMG="$(mktemp img-XXXXXXXXXX.img)"
MNT="$(mktemp -d rootfs-XXXXXXXXXX)"
TMP_FDISK_LOG="$(mktemp /tmp/fdisk-XXXXXXXXXX.log)"


################################################################################
#
# functions
#
################################################################################

function log () {
	echo -e '[\e[1m\e[92mLOG\e[0m  ]: \e[37m'$*'\e[0m'
}

function warn () {
	echo -e '[\e[1m\e[93mWARN\e[0m ]: \e[37m'$*'\e[0m'
}

function error () {
	echo -e '[\e[1m\e[91mERROR\e[0m]: \e[1m\e[97m'$*'\e[0m'
}

function error_and_exit () {
	error "$*"
	false
}

function debug () {
	echo -e '[\e[1m\e[96mDEBUG\e[0m]: \e[37m'$*'\e[0m'
}

function err_handler () {
	error "The last command returned $?."
	# TODO: what needs to be handled insofar as mounted images, etc etc etc
}

################################################################################
#
# trap(s)
#
################################################################################

trap "err_handler" ERR


#################################################################################
#
# some basic checks
#
################################################################################

[[ $UID == 0 ]] || error_and_exit "Must be run as root."
[[ -x $(which qemu-arm-static) ]] || error_and_exit "Could not locate qemu-arm-static in PATH."


#################################################################################
#
# some basic checks
#
#################################################################################

log "Starting ..."

debug "Temporary image file copy: $IMG"
if [[ ! -s "${IMG_ORIG}" ]]; then
	error_and_exit "The specified file '${IMG_ORIG}' could not be found or is an empty file."
fi

log "Making a working copy of image file: $IMG"
pv "${IMG_ORIG}" > $IMG

log "Adding +1G to image size ..."
qemu-img resize -f raw $IMG +1G

log "Resizing second partition (ignore fdisk returning non-zero value) ..."
set +e +E
fdisk $IMG <<-EOF 2>&1 >> $TMP_FDISK_LOG
p
d
2
n
p
2
131072

N
p
w
EOF
set -e -E

log "Creating device maps from images partition table ..."
KPARTX_REGEX_MATCH_STRING='^add map loop.+$'
declare -a img_parts
while read line; do
	debug "    kpartx output: ${line}"
	if [[ $line =~ $KPARTX_REGEX_MATCH_STRING ]]; then
		img_parts+=( /dev/mapper/$(echo $line | awk '{ print $3 }') )
	fi
done < <(kpartx -av $IMG)
debug "${img_parts[@]}"

log "Creating mountpoint: $MNT"
mkdir -p $MNT

log "Sleeping briefly to allow time to create /dev/mapper/ nodes ..."
sleep 1

log "Mounting ${img_parts[1]} on $MNT ..."
mount "${img_parts[1]}" $MNT

log "Mounting ${img_parts[0]} on $MNT/boot ..."
mount "${img_parts[0]}" $MNT/boot

#
# TODO: Check that apt-cacher-ng is actually running.
#
#   The following is assuming that the pi-gen apt-cacher-ng docker image 
#   is running
#
log "Running basic system update in systemd-nspawn chroot ..."
systemd-nspawn -q --bind-ro=/usr/bin/qemu-arm-static -D $MNT /bin/bash -eE <<-EOF
echo 'Acquire::http { Proxy "http://172.17.0.1:3142"; };' > /etc/apt/apt.conf.d/51cache
export http_proxy="http://172.17.0.1:3142"
apt-get update && apt-get upgrade --yes && apt-get autoclean && apt-get autoremove --yes
EOF





