#!/bin/bash

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

set -e
set -E


# =====================================================================
#
# Global Variables
#
# =====================================================================

timestamp="$(date +"%Y%m%d.%H%M")"
orig_img="${1:-3DPrinterOS.img}"
temp_img=$(mktemp ${orig_img//.img}-XXXXXX.img)
temp_img_resize_amt="+1G" # qemu-img units and syntax
temp_img_password_file="${temp_img//.img}-root-password.txt"
random_root_password=""
random_root_password_hash=""


# =====================================================================
#
# ANSI Color Codes
#
# =====================================================================

START='\e[1m'
END='\e[0m'

BLACK='\e[0;30m'
BOLDBLACK='\e[1;30m'
HIBLACK='\e[0;90m'
BOLDHIBLACK='\e[1;90m'

RED='\e[0;31m'
BOLDRED='\e[1;31m'
HIRED='\e[0;91m'
BOLDHIRED='\e[1;91m'

GREEN='\e[0;32m'
BOLDGREEN='\e[1;32m'
HIGREEN='\e[0;92m'
BOLDHIGREEN='\e[1;92m'

YELLOW='\e[0;33m'
BOLDYELLOW='\e[1;33m'
HIYELLOW='\e[0;93m'
BOLDHIYELLOW='\e[1;93m'

CYAN='\e[0;34m'
BOLDCYAN='\e[1;34m'
HIBLUE='\e[0;94m'
BOLDHIBLUE='\e[1;94m'

PURPLE='\e[0;35m'
BOLDPURPLE='\e[1;35m'; 
HIPURPLE='\e[0;95m'
BOLDHIPURPLE='\e[1;95m'

CYAN='\e[0;36m'
BOLDCYAN='\e[1;36m'
HICYAN='\e[0;96m'
BOLDHICYAN='\e[1;96m'

WHITE='\e[0;37m'
BOLDWHITE='\e[1;37m'
HIWHITE='\e[0;97m'
BOLDHIWHITE='\e[1;97m'


# =====================================================================
#
# Functions
#
# =====================================================================

function info () {
  local _key="$1"
  local _value="$2"
  echo -en '['${START}${WHITE}'INFO '${END}']: '
  echo -en ${WHITE}
  printf "%-30s : " "${_key}"
  echo -en ${END}
  echo -e ${BOLDWHITE}${START}"${_value}"${END}
}

function log () {
  echo -e '['${START}${BOLDGREEN}'LOG\e[0m  ]: \e[37m'"$*"'\e[0m'
}

function warn () {
  echo -e '['${START}${BOLDYELLOW}'WARN\e[0m ]: \e[37m'"$*"'\e[0m'
}

function error () {
  echo -e '['${START}${BOLDRED}'ERROR'${END}']: '${START}'\e[97m'"$*"'\e[0m'
}

function error_and_exit () {
  error "$*"
  false
}

function debug () {
  echo -e '['${START}'\e[96mDEBUG\e[0m]: \e[37m'"$*"'\e[0m'
}

function print_header () {
  # 
  # ├─┤ HEADER TEXT ├──────────────────────────────────────┤
  # 
  local _header="$(echo "$*" | tr 'a-z' 'A-Z')"
  local _width=$(( $(tput cols) - "${#1}" - 7 ))
  echo -e '\n'
  echo -en ${START}${WHITE}
  echo -n $'\u251c\u2500\u2524 '         # ├─┤
  echo -en ${END}
  echo -en ${START}${BOLDHICYAN}"${_header}"${END}
  echo -en ${START}${WHITE}
  echo -n $' \u251c'                     # ├
  eval printf $'%.0s\u2500' {1..$_width} #  ──
  echo -n $'\u2524'                      #    ┤
  echo -en ${END}
  echo -e '\n'
}

function err_handler () {
  error "The last command returned $?."
  # TODO: what needs to be handled insofar as mounted images, etc etc etc
}

function cleanup_and_exit () {
  print_header "Exiting & Cleanup"
  log "Cleaning up before exit ..."

  log "Unmounting rootfs/boot ..."
  (mountpoint -q rootfs/boot) && sudo umount rootfs/boot

  log "Unmounting rootfs ..."
  (mountpoint -q rootfs)      && sudo umount rootfs

  log "Deleting device maps for $temp_img ..."
  (sudo losetup -j $temp_img) && sudo kpartx -d $temp_img

  log "Removing temporary image file $temp_img"
  rm -vf -- $temp_img 

  log "Removing root password plaintext file."
  rm -vf -- $temp_img_password_file

  echo -e '\n'${START}${BOLDHIGREEN}'Bye!'${END}
}

function get_img_partition_info () {
  /sbin/parted -m -s $temp_img unit s print
}


# =====================================================================
#
# Traps
#
# =====================================================================

trap "err_handler"  ERR

trap "cleanup_and_exit" EXIT


# =====================================================================
#
# Prepare (base) *.img file for modifications
#
# =====================================================================

print_header "Making Safety Copy of Image"

info "Original img file" "$orig_img"
info "Temporary img file" "$temp_img"
log  "Copying $orig_img to $temp_img ...\n"
pv $orig_img > $temp_img

print_header "Resize Image File"

log "Resizing $temp_img by $temp_img_resize_amt ..."
info "Original size" "$(stat -c '%s' $temp_img)"
qemu-img resize -f raw $temp_img $temp_img_resize_amt >/dev/null
info "New size" "$(stat -c '%s' $temp_img)"


# =====================================================================
#
# Expand size of Linux partition to fill new img size
#
# =====================================================================

print_header "Expand Linux Partition to Fill New Image Size"

start="$(    get_img_partition_info | awk -F: '$1==2       && $5=="ext4" { print $2 }')"
orig_end="$( get_img_partition_info | awk -F: '$1==2       && $5=="ext4" { print $3 }')"
new_end="$(  get_img_partition_info | awk -F: '$1~/\.img$/ && $3=="file" { print $2 }')"
new_end=$(( ${new_end//s} - 1 )) # parted is happier if we back off by one

info "Starting sector is"           "${start//s}"
info "Original ending sector is"    "${orig_end//s}"
info "New ending sector of img is"  "${new_end}"

log "Resizing Linux partition ..."
/sbin/parted -s $temp_img \
  unit s \
  rm 2 \
  mkpart primary ext4 $start $new_end \
  >/dev/null

log "Creating device maps from image file ..."
sudo kpartx -a $temp_img

log "... Sleeping for 1 second ..."
sleep 1

log "Checking filesystem of image's resized Linux partition ..."
sudo e2fsck -f /dev/mapper/loop0p2

log "Resizing filesystem of image's resized Linux partition to fill new, empty space ..."
sudo resize2fs /dev/mapper/loop0p2


# =====================================================================
#
# Create rootfs and rootfs/boot mountpoints and mount image
#
# =====================================================================

print_header "MOUNT IMAGE"

log "Making root mountpoint ..."
mkdir -p rootfs/boot

log "Mounting to rootfs ..."
sudo mount -v /dev/mapper/loop0p2 rootfs

log "Mounting to rootfs/boot ..."
sudo mount -v /dev/mapper/loop0p1 rootfs/boot


# =====================================================================
#
# Create new, random password for image's root user
#
# =====================================================================

print_header "Make New Image Root Password"

random_root_password="$(pwgen -s -cnyB 25 1 | tr -d \'\"\!)"
random_root_password_hash="$(python3 -c 'import sys; import crypt; print(crypt.crypt("'"${random_root_password}"'", crypt.mksalt(crypt.METHOD_SHA512)))')"
info "New root password will be"  "$random_root_password"
info "Password hash is"           "$random_root_password_hash"

set -o noclobber
echo "$random_root_password"      > $temp_img_password_file
echo "$random_root_password_hash" >> $temp_img_password_file
set +o noclobber

info "Root password saved to"     "$temp_img_password_file"


# =====================================================================
#
# Update and base configure mounted image
#
# =====================================================================

print_header "Perform Image Configuration in Cross-Platform Chroot"

log "Changing root password on image ..."
sudo systemd-nspawn -q --bind /usr/bin/qemu-arm-static -D ./rootfs/ /bin/bash <<-EOF
  echo 'root:${random_root_password_hash}' | chpasswd -e
EOF

log "Updating system configurations ..."
sudo systemd-nspawn -q --bind /usr/bin/qemu-arm-static -D ./rootfs/ /bin/bash <<-EOF
  export DEBIAN_FRONTEND=noninteractive
  echo 'America/New_York' > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
  sed -i -e 's/"pc105"/"pc104"/' -e 's/"gb"/"us"/' /etc/default/keyboard
  dpkg-reconfigure -f noninteractive keyboard-configuration
  sed -i -e 's/en_GB.UTF-8/en_US.UTF-8/' /etc/default/locale
  sed -i -e 's/^ *\([a-z].*\)$/# \1/' -e 's/^# *\(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen
  dpkg-reconfigure -f noninteractive locales
EOF

log "Updating packages (this may take awhile) ..."
sudo systemd-nspawn -q --bind /usr/bin/qemu-arm-static -D ./rootfs/ /bin/bash <<-EOF
  echo 'Acquire::http { Proxy "http://172.17.0.1:3142"; };' | tee /etc/apt/apt.conf.d/51cache
  export http_proxy="http://172.17.0.1:3142"
  apt-get update       -qq
  apt-mark             hold   raspberrypi-sys-mods
  apt-get upgrade      -qq    >/dev/null
  apt-mark             unhold raspberrypi-sys-mods
  apt-get upgrade      -qq    >/dev/null
  apt-get dist-upgrade -qq
  apt-get autoremove   -qq
  apt-get autoclean    -qq
  rm -f /etc/apt/apt.conf.d/51cache
EOF

set +eE
log "Dropping you into the image's shell for any custom work ..."
sudo systemd-nspawn -q --bind /usr/bin/qemu-arm-static -D ./rootfs/ /bin/bash
set -eE


# =====================================================================
#
# Copy successful build products to ./builds/ folder
#
# =====================================================================

print_header "Saving to Builds Folder"

mkdir -p builds

cp -v $temp_img builds/${timestamp}-$orig_img
cp -v $temp_img_password_file builds/${timestamp}-${orig_img//.img}-root-password.txt


# =====================================================================
#
# Cleanup and exit
#
# =====================================================================

exit 0
