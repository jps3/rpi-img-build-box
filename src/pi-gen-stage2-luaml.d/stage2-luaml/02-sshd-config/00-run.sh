#!/bin/bash -e

# make initial security changes to sshd_config
on_chroot << EOF
cp -v /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
sed -i -E \
    -e 's/^(#)?PermitRootLogin.*$/PermitRootLogin without-password/' \
    /etc/ssh/sshd_config
sed -i -E \
    -e 's/^(#)?PasswordAuthentication.*$/PasswordAuthentication no/' \
    /etc/ssh/sshd_config
sed -i -E \
    -e 's/^(#)?ChallengeResponseAuthentication.*$/ChallengeResponseAuthentication no/' \
    /etc/ssh/sshd_config
sed -i -E \
    -e 's/^(#)?UsePAM.*$/UsePAM no/' \
    /etc/ssh/sshd_config
EOF

# /boot/ssh[.txt] is a flag used by a Raspbian service unit to
# automatically (force) ssh to start at boot
touch "${ROOTFS_DIR}/boot/ssh.txt"

install -v -m 755 -d                    "${ROOTFS_DIR}/root/.ssh"
install -v -m 600 files/authorized_keys "${ROOTFS_DIR}/root/.ssh/"

log "    # ------------------------------------------------------------ #"
log "    # SSH_PUBKEYS[] : ${#SSH_PUBKEYS[@]} keys defined"
if [[ "${#SSH_PUBKEYS[@]}" -gt 0 ]]; then
	i=0
	for k in "${SSH_PUBKEYS[@]}"; do
		i=$(( $i + 1 ))
		log "        $(printf "%02i %-s" $i "${p}")"
		echo "$p" >> "${ROOTFS_DIR}/root/.ssh/authorized_keys"
	done
fi
log "    # "
log "    # ------------------------------------------------------------ #"

if [[ "${#SSH_PUBKEYS[@]}" -eq 0 ]]; then
	log "    "
	log "    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #"
	log "    # "
	log "    #       W A R N I N G"
	log "    #       YOU DO NOT HAVE ANY INITIAL SSH PUBKEYS DEFINED"
	log "    # "
	log "    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #"
	log "    "
	log "    ... sleeping for 120 sec ... ^C to kill/quit build ..."
	sleep 120
fi


