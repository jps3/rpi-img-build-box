#!/bin/bash

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

set -e


# =====================================================================
#
# Global Variables
#
# =====================================================================

LANG=en_US.UTF-8
LC_CTYPE=en_US.UTF-8

export LANG LC_CTYPE


# =====================================================================
#
# Functions
#
# =====================================================================

function err_handler () {
  # The behavior here has been changed from error() to warn()
  # since in the context of this particular script the return
  # of a non-zero value may not be an "error" per se and
  # thus let us not mislead the reader ...
  warn "The last command returned $?."
}

function cleanup_and_exit () {
  set +x
  print_header "Exiting & Cleanup"
  log "Cleaning up before exit ..."

  warn "( ... your commands here ... )"

  echo -e '\n'${START}${BOLDHIGREEN}'Bye!'${END}
}


# =====================================================================
#
# Source additional "libs"
#
# =====================================================================

source $(dirname $0)/lib-colors-logging.sh


# =====================================================================
#
# Traps
#
# =====================================================================

trap "err_handler"  ERR

trap "cleanup_and_exit" EXIT


# =====================================================================
#
# Start
#
# =====================================================================

print_header "Start of $(basename $0)"

printenv | sort -t= -k1 | grep ^SALT

if [[ -z "$SALT_MASTER" ]]; then
  error_and_exit "\$SALT_MASTER not defined or no value assigned."
else
  SALT_MASTER="-A ${SALT_MASTER}"
fi

if [[ -z "$SALTSTACK_BRANCH" ]]; then
  error_and_exit "\$SALTSTACK_BRANCH not defined or no value assigned."
fi

if [[ -z "$SALTSTACK_VERSION" ]]; then
  error_and_exit "\$SALTSTACK_VERSION not defined or no value assigned."
fi


# =====================================================================
#
# Remove user 'pi' if present
#
# =====================================================================

print_header "Removing user 'pi'"

if (id pi >/dev/null 2>/dev/null); then

  read -a pi_groups <<< $(id -Gn pi)

  log "Removing user 'pi' as member from from ${#pi_groups[@]} groups ..."
  for gid in "${pi_groups[@]}"; do 
    info "Removing from group: ${gid} ..."
    deluser pi $gid >/dev/null || warn "Error removing from ${gid}"
  done

  log "Deleting user 'pi' ..."
  set +e; userdel -r pi; set -e

  log "Deleting group 'pi' (as needed) ..."
  set +e; delgroup pi; set -e

  log "Deleting sudoers.d/010_pi-nopasswd ..."
  rm -fv /etc/sudoers.d/010_pi-nopasswd

else
  warn "User 'pi' does not exist apparently. Skipping ..."
fi


# =====================================================================
#
# Make some security-related updates to /etc/ssh/sshd_config
#
# =====================================================================

print_header "sshd Security Changes"

if [[ ! -f /etc/ssh/sshd_config.orig ]]; then
  log "Backing up /etc/ssh/sshd_config to /etc/ssh/sshd_config.orig"
  cp -v /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
fi

log "Setting PermitRootLogin to without-password ..."
sed -i -E -e 's/^(#)?PermitRootLogin.*$/PermitRootLogin without-password/' /etc/ssh/sshd_config

sshd_config_keywords_set_to_no=(
  PasswordAuthentication
  ChallengeResponseAuthentication
  UsePAM
  )
for k in "${sshd_config_keywords_set_to_no}"; do
  log "Setting ${k} to 'no' ..."
  sed -i -E -e 's/^(#)?'$k'.*$/'$k' no/' /etc/ssh/sshd_config
done

log "diff of changes to sshd_config"
set +e
>&2 diff -uw /etc/ssh/sshd_config.orig /etc/ssh/sshd_config
set -e


# =====================================================================
#
# Add some ssh pubkeys to root user authorized_keys
#
# =====================================================================

print_header "Adding root ssh pubkeys"
(umask 0077 && mkdir -p /root/.ssh)
for ssh_pubkey in /vagrant/ssh-pubkeys/*.pub; do
  info "+ ${ssh_pubkey}"
  cat $ssh_pubkey >> /root/.ssh/authorized_keys
done


# =====================================================================
#
# Enable sshd
#
# =====================================================================

print_header "Enabling sshd"
if [[ -f /lib/systemd/system/sshswitch.service ]]; then
	info "Using the Raspbian way"
  set -x; touch /boot/ssh.txt; set +x
else
	warn "Likely not a Raspbian-based image, using alt method ... "
	set -x; update-rc.d ssh enable; set +x
fi


# =====================================================================
#
# Manual systemd service changes
#
# =====================================================================

print_header "Additional systemd changes"

log "Removing 'triggerhappy.service' symlink ..."
set -x
rm -fv /etc/systemd/system/multi-user.target.wants/triggerhappy.service
set +x

log "Done with additional systemd changes."


#
# This 3DPoS crap does not belong in this script
#
# # =====================================================================
# #
# # Additional packages
# #
# # =====================================================================
# 
# print_header "Installing packages supporting 3DPrinterOS Client"
# 
# addl_pkgs=(
#   virt-what
#   opencv-data
#   python-opencv
#   python-numpy
#   python-libusb1
#   libusb-1.0-0
#   python-notify2
#   fail2ban
# )
# 
# log "Updating apt caches ..."
# apt-get update -qq
# 
# log "Installing ${#addl_pkgs[@]} additional packages ..."
# for pkg in "${addl_pkgs[@]}"; do
#   info "Installing $pkg ..."
#   apt-get install --no-install-recommends -qq $pkg
# done
# 
# log "Installation of additional packages completed."


# =====================================================================
#
# Install Saltstack
#
# =====================================================================

print_header "Install salt-minion"

# use `lsb_release` values
LSB_RELEASE="$(echo $(lsb_release -sr) 1 / p | dc)"
debug "LSB_RELEASE: ${LSB_RELEASE}"

LSB_CODENAME="$(lsb_release -sc)"
debug "LSB_CODENAME: ${LSB_CODENAME}"

DPKG_ARCH="$(dpkg --print-architecture)"
debug "DPKG_ARCH: ${DPKG_ARCH}"

curl -sLf https://bootstrap.saltstack.com | \
  /bin/sh -s -- -X -F ${SALT_MASTER} ${SALTSTACK_BRANCH} ${SALTSTACK_VERSION}

if (pgrep -c -f salt-minion >/dev/null); then
  log "Killing running salt-minion ..."
  pkill -f salt-minion
fi

log "(Force) remove minion_id file ..."
rm -fv /etc/salt/minion_id

set +e
log "Removing any generated keys in /etc/salt/pki ..."
find /etc/salt/pki -type f -delete
set -

#if [[ -n "${SALT_MASTER}" ]]; then
#  info "Setting salt-minion 'master' to" "${SALT_MASTER}"
#  cat <<-EOF >/etc/salt/minion.d/00-master.conf
#master: ${SALT_MASTER}
#EOF
#fi

log "Creating empty grains file (for now)"
touch /etc/salt/grains


# =====================================================================
#
# Done
#
# =====================================================================

print_header "End of $(basename $0)"

exit 0
