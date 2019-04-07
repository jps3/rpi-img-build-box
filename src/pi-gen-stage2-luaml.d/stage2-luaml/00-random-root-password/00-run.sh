#!/bin/bash -e

apt-get update
apt-get install -y -q jq python3

PASSWORD_LENGTH="${ROOT_PASSWORD_LENGTH:-18}"
log "    INFO -- PASSWORD_LENGTH is $PASSWORD_LENGTH"

ROOT_PASSWORD_RECORD_FILE="${STAGE_DIR}/root-random-password-record.json"
log "    INFO -- ROOT_PASSWORD_RECORD_FILE is $ROOT_PASSWORD_RECORD_FILE"

./generate_random_password.py -l $PASSWORD_LENGTH  | \
  tee "${ROOT_PASSWORD_RECORD_FILE}"               | \
  jq -C .

log "    INFO -- (contents of $ROOT_PASSWORD_RECORD_FILE): $(cat "${ROOT_PASSWORD_RECORD_FILE}")"

chmod 0400 "${ROOT_PASSWORD_RECORD_FILE}"

RANDOM_ROOT_PASSWORD_HASH="$(jq -r .encrypted "${ROOT_PASSWORD_RECORD_FILE}")"

on_chroot << EOF
  set -x
  echo 'root:${RANDOM_ROOT_PASSWORD_HASH}' | chpasswd -e
  set +x
EOF

log "    INFO -- set root password on target using 'chpasswd -e'"
