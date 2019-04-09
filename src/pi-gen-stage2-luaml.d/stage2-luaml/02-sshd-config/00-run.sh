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


log "    # ------------------------------------------------------------ #"
log "    # "
log "    # SSH_PUBKEY"
log "    # "
log "    # ------------------------------------------------------------ #"

install -v -m 755 -d                    "${ROOTFS_DIR}/root/.ssh"
install -v -m 600 files/authorized_keys "${ROOTFS_DIR}/root/.ssh/"

tmpfile=$(mktemp -t ssh_pubkey_XXXXXX)

if [[ -z "${SSH_PUBKEY}" ]]; then
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
else
	echo "${SSH_PUBKEY}" | tee $tmpfile
	if (ssh-keygen -l -f $tmpfile); then
		cat $tmpfile >> "${ROOTFS_DIR}/root/.ssh/authorized_keys"
		log "    INFO added SSH_PUBKEY to target /root/.ssh/authorized_keys"
	else
		log "    ERROR -- ssh-keygen returned an error verifying SSH_PUBKEY"
		exit -1
	fi
fi
