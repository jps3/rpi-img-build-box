#!/bin/bash -e


log "    # ------------------------------------------------------------ #"
log "    # "
log "    # sshd_config alterations"
log "    # "
log "    # ------------------------------------------------------------ #"

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
log "    INFO forced PermitRootLogin to 'without-password'"
log "    INFO forced PasswordAuthentication to 'no'"
log "    INFO forced ChallengeResponseAuthentication to 'no'"
log "    INFO forced UsePAM to 'no'"

log "    # ------------------------------------------------------------ #"
log "    # "
log "    # PUBKEY_SSH_ROOT"
log "    # "
log "    # ------------------------------------------------------------ #"

install -v -m 755 -d                    "${ROOTFS_DIR}/root/.ssh"
install -v -m 600 files/authorized_keys "${ROOTFS_DIR}/root/.ssh/"

tmpfile=$(mktemp -t ssh_pubkey_XXXXXX)

if [[ -z "${PUBKEY_SSH_ROOT}" ]]; then
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
	echo "${PUBKEY_SSH_ROOT}" | tee $tmpfile
	if (ssh-keygen -l -f $tmpfile); then
		cat $tmpfile >> "${ROOTFS_DIR}/root/.ssh/authorized_keys"
		log "    INFO added PUBKEY_SSH_ROOT to target /root/.ssh/authorized_keys"
	else
		log "    ERROR -- ssh-keygen returned an error verifying PUBKEY_SSH_ROOT"
		exit -1
	fi
fi
