#!/bin/bash -ex

# ---------------------------------------------------------------------- #
#                                                                        #
#  This script's purpose is to prepare the primary Git repository's      #
#  stage* steps and files, and the build scripts such that the           #
#  addition of `stage2-luaml` will work correctly.                         #
#                                                                        #
#  Additionally, many of the default settings made are aimed at          #
#  defaults for UK English locale and keyboard layouts, which is         #
#  annoying. It is simpler to change these *now* and up-front.           #
#                                                                        #
# ---------------------------------------------------------------------- #


if [[ $USER != "vagrant" ]]; then
    log "Must be run as user 'vagrant' not '$USER'."
    exit -1
fi


# ---------------------------------------------------------------------- #
#  VARS
# ---------------------------------------------------------------------- #

unwanted_package_names=(
    "apt-listchanges"
    "avahi-daemon"
    "build-essential"
    "crda"
    "debconf-utils"
    "gdb"
    "libfreetype6-dev"
    "libmtp-runtime"
    "libraspberrypi-dev"
    "libraspberrypi-doc"
    "lua5.1"
    "luajit"
    "man-db"
    "manpages-dev"
    "ncdu"
    "pkg-config"
    "psmisc"
    "python-rpi.gpio"
    "rpi-update"
    "strace"
    "v4l-utils"
    "cifs-utils"
    "firmware-atheros"
    "firmware-brcm80211"
    "firmware-libertas"
    "firmware-misc-nonfree"
    "firmware-realtek"
    )


# ---------------------------------------------------------------------- #
#  Functions
# ---------------------------------------------------------------------- #

function log () {
    >&2 printf "[INFO] %-s\n" "$*"
}

##
##  remove_unwanted_package_names_from_file()
## 
##    Edit out (remove) package names which we do **NOT** want to be
##    installed and clean up whitespacing.
##   
##    The manipulation of the IFS env var and the arrays of 
##    package names provides a convenient means for "converting"
##    to a '(pkga|pkgb|...|pkgX)' string which is then evaluated
##    as a regular expression by `sed`
##

function remove_unwanted_package_names_from_file () {
    if [[ -e "$1" ]]; then
        IFS='|'
        sed -E -i \
            -e 's/\b('"${unwanted_package_names[*]}"')\b//g' \
            -e 's/  */ /g' \
            -e 's/  *$//'  \
            -e 's/^  *//'  \
            "$1"
    else
       log "The target file '$1' does not appear to exist."
    fi
}


# ---------------------------------------------------------------------- #
#  BEGIN                                                                 #
# ---------------------------------------------------------------------- #

cd ~/build/pi-gen/


# ---------------------------------------------------------------------- #
#  Set debconf locale and keyboard settings to US English
#  Note: The debconf settings are made **BEFORE** the relevant 
#        packages (ie locales, keyboard-configuration, etc.) are 
#        installed.
# ---------------------------------------------------------------------- #

sed -i \
    -e '/^[^#]/ s/en_GB/en_US/g' \
    stage0/01-locale/00-debconf


# ---------------------------------------------------------------------- #
#  Set base pi-gen build script 'config' file env vars
# ---------------------------------------------------------------------- #

set -o noclobber
cat <<EOF >config
IMG_NAME=""
APT_PROXY="http://172.17.0.1:3142"
FIRST_USER_NAME="luamluser"
FIRST_USER_PASS="$(pwgen -1 32 1)"
ENABLE_SSH="1"
EOF
set +o noclobber

sed -E -i \
    -e '/FIRST_USER_PASS.* chpasswd/ a passwd -l $FIRST_USER_NAME ' \
    -e '/root:root.*chpasswd/ a passwd -l root' \
    stage1/01-sys-tweaks/00-run.sh


# ---------------------------------------------------------------------- #
#
#  stage2/01-sys-tweaks/
# 
# ---------------------------------------------------------------------- #

sed -i \
    -e '/^[^#]/ s/Generic 105-key (Intl) PC/Generic 104-key PC/' \
    -e '/^[^#]/ s/select\([[:space:]]\)\{1,\}gb/select\1us/' \
    -e '/^[^#]/ s/English (UK)/English (US)/' \
    stage2/01-sys-tweaks/00-debconf

sed -i \
    -e 's/FONTFACE=.*$/FONTFACE="Terminus"/' \
    -e 's/FONTSIZE=.*$/FONTSIZE="8x16"/' \
    stage2/01-sys-tweaks/files/console-setup


# ---------------------------------------------------------------------- #
#  Remove unwanted package names from "*-packages*" files
# ---------------------------------------------------------------------- #

packages_files=( 
    $(find stage{0..2} -type f -name "*-packages*") 
    )

log_lines="$(
    printf \
        "Found %i files like '*-packages*' ..." \
        "${#packages_files[@]}"
    )"
log "$log_lines"

for packages_file in "${packages_files[@]}"; do
    log_line="$(printf "> Processing: %45s" "$packages_file")"
    log "$log_line"
    remove_unwanted_package_names_from_file "$packages_file"
done


# ---------------------------------------------------------------------- #
#  Set file flags to skip unnecessary stage3+ builds and image exports
# ---------------------------------------------------------------------- #

set +e

touch stage{3..5}/SKIP

find stage{2..5} -type f -name "EXPORT_*" -exec dirname {} \; | \
    uniq | \
    xargs -I{} touch {}/SKIP_IMAGES

set -e


# ---------------------------------------------------------------------- #
#  config-luaml
# ---------------------------------------------------------------------- #

set -o noclobber
cat <<EOF >config-luaml
TIMEZONE="America/New_York"
ROOT_PASSWORD_LENGTH="22"
SALTSTACK_VERSION="stable 2017.7"
SALT_MASTER=""
EOF
set +o noclobber


# ---------------------------------------------------------------------- #
#  Copy in stage2-luaml
# ---------------------------------------------------------------------- #

if [[ -d /vagrant/src/pi-gen-stage2-luaml.d ]]; then
    rsync -crlptog --exclude .git /vagrant/src/pi-gen-stage2-luaml.d/ ./
fi


# ---------------------------------------------------------------------- #
#  Custom *.deb files
# ---------------------------------------------------------------------- #

if [[ -d stage2-luaml/99-custom-deb-pkgs/files/ ]]; then
    find /vagrant/src -type d -iname debian -exec dirname {} \; | \
    while read debdir; do
        fakeroot dpkg-deb -b "${debdir}"
    done
    cp -v /vagrant/src/*.deb stage2-luaml/99-custom-deb-pkgs/files/
fi


# ---------------------------------------------------------------------- #
#  END                                                                   #
# ---------------------------------------------------------------------- #
