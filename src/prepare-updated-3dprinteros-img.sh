#!/bin/bash

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

set -e
set -E


# =====================================================================
#
# User-Defined Variables
#
# =====================================================================

salt_master_hostname="${2:-}"

random_root_password_length=20

additional_packages=( 
    "apt-transport-https"
    "ca-certificates"
    "jq"
    "lsb-release"
    "rsync"
  )

files_to_chattr=()

#files_to_chattr=(
#  "etc/passwd"
#  "etc/passwd-"
#  "etc/shadow"
#  "etc/shadow-"
#  "etc/ssh/sshd_config"
#  "root/.ssh/authorized_keys"
#  )

purge_packages=()


# =====================================================================
#
# Global Variables
#
# =====================================================================

timestamp_start="$(date +"%s")"

orig_img="${1:-3DPrinterOS.img}"

temp_img=$(mktemp ${orig_img//.img}-XXXXXX.img)
#temp_img_resize_amt="+250M" # qemu-img units and syntax
temp_img_password_file="${temp_img//.img}-root-password.txt"


# =====================================================================
#
# Complex Command Substitutions
#
# =====================================================================

systemd_nspawn_cmd='
  systemd-nspawn 
  -q 
  --bind /usr/bin/qemu-arm-static 
  --bind /vagrant 
  -D 
  ./rootfs/
'


# =====================================================================
#
# Source additional "libs"
#
# =====================================================================

source $(dirname $0)/lib-colors-logging.sh


# =====================================================================
#
# Functions
#
# =====================================================================

function err_handler () {
  error "The last command returned $?."
  # TODO: what needs to be handled insofar as mounted images, etc etc etc
}

function cleanup_and_exit () {
  set +x
  print_header "Exiting & Cleanup"
  log "Cleaning up before exit ..."

  log "Unmounting rootfs/boot ..."
  (mountpoint -q rootfs/boot) && sudo umount rootfs/boot

  log "Unmounting rootfs ..."
  (mountpoint -q rootfs)      && sudo umount rootfs

  log "Deleting device maps for $temp_img ..."
  (sudo losetup -j $temp_img | grep -q ^/dev/loop) && \
    sudo kpartx -dv $temp_img

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

if [[ $temp_img =~ .*-updated.*.img ]]; then
  warn "Filename contains '-update', assuming customized image ..."
  debug "Removing initial temporary file ${temp_img} ..."
  rm -f $temp_img
  temp_img="$(echo $temp_img | sed -e 's/-updated/-updated-custom/')"
fi

info "Temporary img file" "$temp_img"
log  "Copying $orig_img to $temp_img ...\n"
pv $orig_img > $temp_img


# # =====================================================================
# #
# # Enlarge (resize) image file if not an -update.img file
# #
# # =====================================================================
# 
# print_header "Resize Image File"
# 
# if [[ $temp_img =~ .*-updated.*.img ]]; then
#   warn "Skipping. Filename contains '-update' ..."
# else
#   log "Resizing $temp_img by $temp_img_resize_amt ..."
#   info "Original size" "$(stat -c '%s' $temp_img)"
#   qemu-img resize -f raw $temp_img $temp_img_resize_amt >/dev/null
#   info "New size" "$(stat -c '%s' $temp_img)"
# fi


# # =====================================================================
# #
# # Expand size of Linux partition to fill new img size
# #
# # =====================================================================
# 
# print_header "Expand Linux Partition to Fill New Image Size"
# 
# if [[ $temp_img =~ .*-updated.*.img ]]; then
# 
#   warn "Skipping. Filename contains '-update' ..."
# 
# else
# 
#   start="$(    get_img_partition_info | \
#     awk -F: '$1==2       && $5=="ext4" { print $2 }')"
# 
#   orig_end="$( get_img_partition_info | \
#     awk -F: '$1==2       && $5=="ext4" { print $3 }')"
# 
#   new_end="$(  get_img_partition_info | \
#     awk -F: '$1~/\.img$/ && $3=="file" { print $2 }')"
#   new_end=$(( ${new_end//s} - 1 )) # parted is happier if we back off by one
# 
#   info "Starting sector is"           "${start//s}"
#   info "Original ending sector is"    "${orig_end//s}"
#   info "New ending sector of img is"  "${new_end}"
# 
#   log "Resizing Linux partition ..."
#   /sbin/parted -s $temp_img \
#     unit s \
#     rm 2 \
#     mkpart primary ext4 $start $new_end \
#     >/dev/null
# 
#   log "Creating partition mappings from image file ..."
#   read -a loop_maps <<< $( 
#     sudo kpartx -av $temp_img | \
#     awk '$0~/^add map/ { printf("%s ",$3) }'
#   )
#   debug 'loop_maps=( '"${loop_maps[@]}"' )'
# 
#   log "... Sleeping for 1 second ..."
#   sleep 1
# 
#   log "Checking filesystem of image's resized Linux partition ..."
#   sudo e2fsck -f /dev/mapper/"${loop_maps[1]}"
# 
#   log "Resizing image's Linux partition to fill extended space ..."
#   sudo resize2fs /dev/mapper/"${loop_maps[1]}"
# 
#   log "... Sleeping for 1 second ..."
#   sleep 1
# 
#   log "Deleting partition mappings for image file ..."
#   sudo kpartx -dv $temp_img
# 
# fi


# =====================================================================
#
# Create rootfs and rootfs/boot mountpoints and mount image
#
# =====================================================================

print_header "Mount Image"

log "Creating partition mappings for image file ..."
read -a loop_maps <<< $( 
  sudo kpartx -av $temp_img | \
  awk '$0~/^add map/ { printf("%s ",$3) }'
)
debug 'loop_maps=( '"${loop_maps[@]}"' )'

log "... Sleeping for 1 second ..."
sleep 1

log "Making rootfs mountpoint ..."
mkdir -p rootfs

log "Mounting to rootfs ..."
sudo mount -v /dev/mapper/"${loop_maps[1]}" rootfs

log "Mounting to rootfs/boot ..."
sudo mount -v /dev/mapper/"${loop_maps[0]}" rootfs/boot


# =====================================================================
#
# Create new, random password for image's root user
#
# =====================================================================

print_header "Update Root Password on Image"

log "Generating new random password for root user on image ..."
set -o noclobber
/usr/bin/env python3 <<EOF > $temp_img_password_file
import base64
import crypt
import random
import string
password_len = ${random_root_password_length:-20}
all_chars = string.ascii_letters + string.punctuation + string.digits
password = "".join(random.choice(all_chars) for x in range(0, password_len))
encoded = base64.b64encode(password.encode())
hash = crypt.crypt(password, crypt.mksalt(crypt.METHOD_SHA512))
print("{p}\n{e}\n{h}\n".format(p=password, e=encoded, h=hash))
EOF
set +o noclobber

log "A copy of the cleartext password and hash saved to $temp_img_password_file"

random_root_password_hash="$(sed -n '/^\$6\$/p' $temp_img_password_file)"

if [[ -n "${random_root_password_hash}" ]]; then
  log "Changing root password on image ..."
  sudo $systemd_nspawn_cmd /bin/bash <<-EOF
    echo 'root:${random_root_password_hash}' | chpasswd -e
    sleep 1
EOF
  log "Password changed for root on image."
else
  error "\$random_root_password_hash variable is empty."
fi


# =====================================================================
#
# Update Base Image
#
# =====================================================================

print_header "Update Base Image"

if [[ $temp_img =~ .*-updated.*.img ]]; then

  warn "Skipping. Filename contains '-update' ..."

else

  log "Updating system configurations ..."
  sudo $systemd_nspawn_cmd /bin/bash <<-EOF
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
  sudo $systemd_nspawn_cmd /bin/bash <<-EOF
    echo 'Acquire::http { Proxy "http://172.17.0.1:3142"; };' | tee /etc/apt/apt.conf.d/51cache
    export http_proxy="http://172.17.0.1:3142"
    apt-get update          -qq
    # apt-mark               hold  raspberrypi-sys-mods
    # apt-get upgrade         -qq
    # apt-mark             unhold  raspberrypi-sys-mods
    apt-get upgrade         -qq
    apt-get dist-upgrade    -qq
    # apt-get purge           -qq  ${purge_packages[@]}
    apt-get autoremove      -qq
    apt-get autoclean       -qq
    rm -f /etc/apt/apt.conf.d/51cache
EOF

  log "Creating a backup copy of the updated image ..."
  log "Unmounting rootfs/boot ..."
  sudo umount rootfs/boot
  log "Unmounting rootfs ..."
  sudo umount rootfs
  log "Deleting partition mappings for"  "${temp_img}"
  sudo kpartx -dv $temp_img
  temp_img_backup=${temp_img//.img/-updated.img}
  info "Setting backup copy filename to" "${temp_img_backup}"
  pv $temp_img > $temp_img_backup

  log "Done making backup copy."

#  read -p "Return to continue, Q to quit ... "
#  case $REPLY in
#    Q|q)  cp $temp_img_password_file ${temp_img_password_file}-copy
#          exit 0;;
#    *) ;;
#  esac

  log "Creating partition mappings from image file ..."
  read -a loop_maps <<< $( 
    sudo kpartx -av $temp_img | \
    awk '$0~/^add map/ { printf("%s ",$3) }'
  )
  debug 'loop_maps=( '"${loop_maps[@]}"' )'

  log "... Sleeping for 1 second ..."
  sleep 1

  sudo mount /dev/mapper/"${loop_maps[1]}" rootfs
  sudo mount /dev/mapper/"${loop_maps[0]}" rootfs/boot

fi


# =====================================================================
#
# Customizing Updated Image
#
# =====================================================================

print_header "Customize Updated Image"

log "Install additional packages ..."
sudo $systemd_nspawn_cmd /bin/bash -x <<-EOF
  echo 'Acquire::http { Proxy "http://172.17.0.1:3142"; };' | \
    tee /etc/apt/apt.conf.d/51cache
  export http_proxy="http://172.17.0.1:3142"
  apt-get update          -qq
  apt-get install         -qq  ${additional_packages[@]}
  rm -f /etc/apt/apt.conf.d/51cache
EOF

log "Disable undesired systemd units/services in image ..."
sudo $systemd_nspawn_cmd /bin/bash -x <<-EOF
  rm -vf /etc/systemd/system/multi-user.target.wants/3dprinteros*
  rm -vf /etc/systemd/system/multi-user.target.wants/avahi-daemon.service
  rm -vf /etc/systemd/system/sockets.target.wants/avahi-daemon.socket
  rm -vf /etc/systemd/system/dbus-org.bluez.service 
  rm -vf /etc/systemd/system/dbus-org.freedesktop.Avahi.service
EOF

log "Rsync'ing in local systemd unit to set unique hostname on boot ..."
sudo rsync -rlptv /vagrant/src/set-unique-hostname-before-network/ rootfs/
#sudo find rootfs/ -user 1000 -exec chown root:root {} + 2>/dev/null

log "Enabling set-unique-hostname-before-network.service ..."
sudo $systemd_nspawn_cmd /bin/bash -x <<-EOF
  mkdir -p  /etc/systemd/system/network.target.wants     && \
  cd        /etc/systemd/system/network.target.wants     && \
  ln -svf ../set-unique-hostname-before-network.service
EOF

log "Running saltstack-prep-and-install.sh ..."
sudo $systemd_nspawn_cmd \
  /vagrant/src/saltstack-prep-and-install.sh

#log "Dropping you into the image's shell for any custom work ..."
#warn "You can avoid errors on exit by using 'exit 0' not ^D"
#sudo $systemd_nspawn_cmd /bin/bash


# =====================================================================
#
# Unmount filesystem(s) and delete partition mappings
#
# =====================================================================

print_header "Perform chattrs for Hack-y File Protections"

(
  cd rootfs && \
  if [[ "${#files_to_chattr[@]}" -gt 0 ]]; then
    for file in "${files_to_chattr[@]}"; do
      sudo chattr -V +i "${file}"
    done
  fi
)


# =====================================================================
#
# Unmount filesystem(s) and delete partition mappings
#
# =====================================================================

print_header "Unmount Image"

log "Unmounting rootfs/boot ..."
sudo umount -v rootfs/boot

log "Unmounting rootfs ..."
sudo umount -v rootfs

log "Deleting rootfs mountpoint ..."
rmdir -pv rootfs

log "Deleting partition mappings for image file ..."
sudo kpartx -dv $temp_img


# =====================================================================
#
# Copy successful build products to ./builds/ folder
#
# =====================================================================

print_header "Saving to Builds Folder"

pv $temp_img               > builds/${timestamp_start}-$orig_img
pv $temp_img_password_file > builds/${timestamp_start}-${orig_img//.img}-root-password.txt
sudo chown vagrant:vagrant builds/*


# =====================================================================
#
# Cleanup and exit
#
# =====================================================================

timestamp_end="$(date +%s)"
info "Workflow duration:" "$(( $timestamp_end - $timestamp_start )) seconds"

exit 0
