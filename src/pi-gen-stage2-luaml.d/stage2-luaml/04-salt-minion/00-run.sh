#!/bin/bash -e

log "    # ------------------------------------------------------------ #"
log "    # INFO"
log "    #"
log "    # SALT_MASTER        : '${SALT_MASTER}'"
log "    # SALTSTACK_BRANCH   : '${SALTSTACK_BRANCH}'"
log "    # SALTSTACK_VERSION  : '${SALTSTACK_VERSION}'"
log "    # SALT_ENABLED       : '${SALT_ENABLED}'"
log "    #"
log "    # ------------------------------------------------------------ #"

install -v -m 644 files/50-master.conf "${ROOTFS_DIR}/tmp/"

on_chroot << EOF
set -x
source /etc/os-release
SALTSTACK_REPO_URL="https://repo.saltstack.com/apt/\${ID_LIKE}/\${VERSION_ID}/armhf/\${SALTSTACK_VERSION}"
if ! (dpkg-query --show salt-minion); then 
  wget -O - \${SALTSTACK_REPO_URL}/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
  echo "deb \${SALTSTACK_REPO_URL} stretch main" | tee /etc/apt/sources.list.d/saltstack.list
  apt-get update -y
  apt-get install -y salt-minion
  mkdir -p /etc/salt/minion.d
  if [[ -n "${SALT_MASTER}" ]]; then
	  install -v -m 644 /tmp/50-master.conf /etc/salt/minion.d/
	  sed -i -E \
	    -e '/^#master:/s/^#//' \
	    -e '/^master:/s/\bSALT_MASTER\b/'${SALT_MASTER}'/' \
	    /etc/salt/minion.d/50-master.conf
  fi
else
  echo "... salt-minion already installed (skipping this step) ..."
fi
set +x
EOF

log "    # ------------------------------------------------------------ #"
log "    # Cleaning up ..."
log "    # ------------------------------------------------------------ #"

on_chroot << EOF
	set -x
	rm -fv /etc/salt/minion_id
	rm -fv /etc/salt/pki/minion/minion.p*
EOF

log "    SALT_ENABLED is \"${SALT_ENABLED}\""

if ! $SALT_ENABLED; then
	log "        Disabling salt-minion service on target ..."
	on_chroot << EOF
		systemctl disable salt-minion || \
			find /etc/systemd/system -name salt-minion.service -type l -delete
EOF
else
	log "        Enabling salt-minion service on target ..."
	on_chroot << EOF
	  systemctl enable salt-minion
EOF
fi

log "    # ------------------------------------------------------------ #"
log "    # end of saltstack installation script"
log "    # ------------------------------------------------------------ #"

