#!/bin/bash -e

# shellcheck source=/home/vagrant/build/pi-gen/config-luaml
source "${BASE_DIR}"/config-luaml

export ROOT_PASSWORD_LENGTH

apt-get update
apt-get install -y -q jq python3

PASSWORD_LENGTH="${ROOT_PASSWORD_LENGTH:-18}"
echo "# INFO # PASSWORD_LENGTH is $PASSWORD_LENGTH"

ROOT_PASSWORD_RECORD_FILE="${ROOTFS_DIR}/root/root-random-password-record.json"

./generate_random_password.py -l $PASSWORD_LENGTH  | \
  tee "${ROOT_PASSWORD_RECORD_FILE}"                    | \
  jq -C .

chmod 0400 "${ROOT_PASSWORD_RECORD_FILE}"

RANDOM_ROOT_PASSWORD_HASH="$(jq -r .encrypted "${ROOT_PASSWORD_RECORD_FILE}")"

on_chroot << EOF
  set -x
  echo 'root:${RANDOM_ROOT_PASSWORD_HASH}' | chpasswd -e
  set +x
EOF
