#!/bin/bash -e

# shellcheck source=/home/vagrant/build/pi-gen/config-luaml
source "${BASE_DIR}"/config-luaml

export SSH_PUBKEYS


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

for p in "${SSH_PUBKEYS[@]}"; do
	printf '%s\n' "$p" | tee -a "${ROOTFS_DIR}/root/.ssh/authorized_keys"
done



