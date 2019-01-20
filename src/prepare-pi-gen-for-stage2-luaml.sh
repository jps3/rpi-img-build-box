#!/bin/bash -e

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

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

shopt -u sourcepath


# ---------------------------------------------------------------------- #
#  VARS
# ---------------------------------------------------------------------- #

#
# Identifying these requires periodically reviewing the contents
# of the official pi-gen repository's stage* directories for 
# files like *-packages and looking at the contents for items
# not wanted or needed for stage2-luaml builds (ie. cruft)
#
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

source /vagrant/src/lib-colors-logging.sh

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

print_header "BEGIN"

if [[ $USER != "vagrant" ]]; then
    error_and_exit "Must be run as user 'vagrant' not '$USER'."
fi

cd ~/build/pi-gen/
info "PWD" "$(pwd)"


# ---------------------------------------------------------------------- #
#  stage0/01=locale
# ---------------------------------------------------------------------- #

print_header "stage0/01-locale"

#
#  Set debconf locale and keyboard settings to US English
#  Note: The debconf settings are made **BEFORE** the relevant 
#        packages (ie locales, keyboard-configuration, etc.) are 
#        installed.
#

target="stage0/01-locale/00-debconf"
sed -i \
    -e '/^[^#]/ s/en_GB/en_US/g' \
    "${target}"
log "Changed ${target} instances of en_GB to en_US"


# ---------------------------------------------------------------------- #
#  Set base pi-gen build script 'config' file env vars
# ---------------------------------------------------------------------- #

print_header "pi-gen config file"

cat <<EOF >config
IMG_NAME=""
APT_PROXY="http://172.17.0.1:3142"
FIRST_USER_NAME="luamluser"
FIRST_USER_PASS="$(pwgen -1 32 1)"
ENABLE_SSH="1"
STAGE_LIST="stage0 stage1 stage2 stage2-luaml"
EOF
log "Added file 'config'"


# ---------------------------------------------------------------------- #
#  stage2/01-sys-tweaks/
# ---------------------------------------------------------------------- #

print_header "stage1/01-sys-tweaks"

target="stage1/01-sys-tweaks/00-run.sh"
sed -E -i \
    -e '/FIRST_USER_PASS.* chpasswd/ a passwd -l $FIRST_USER_NAME ' \
    -e '/root:root.*chpasswd/ a passwd -l root' \
    "${target}"
log "Changed ${target} to disable first user"


# ---------------------------------------------------------------------- #
#  stage2/01-sys-tweaks/
# ---------------------------------------------------------------------- #

print_header "stage2/01-sys-tweaks"

target="stage2/01-sys-tweaks/00-debconf"
sed -i \
    -e '/^[^#]/ s/Generic 105-key (Intl) PC/Generic 104-key PC/' \
    -e '/^[^#]/ s/select\([[:space:]]\)\{1,\}gb/select\1us/' \
    -e '/^[^#]/ s/English (UK)/English (US)/' \
    "${target}"
log "Changed ${target} to change from GB to US keyboard"

target="stage2/01-sys-tweaks/files/console-setup"
sed -i \
    -e 's/FONTFACE=.*$/FONTFACE="Terminus"/' \
    -e 's/FONTSIZE=.*$/FONTSIZE="8x16"/' \
    "${target}"
log "Changed ${target} to use Terminus font"


# ---------------------------------------------------------------------- #
#  Remove unwanted package names from "*-packages*" files
# ---------------------------------------------------------------------- #

print_header "Remove unwanted package names from stages"

packages_files=( 
    $(find stage{0..2} -type f -name "*-packages*") 
    )
info "Found *-packages files" "${#packages_files[@]}"

for packages_file in "${packages_files[@]}"; do
    remove_unwanted_package_names_from_file "$packages_file"
    log "Processed $packages_file to remove unwanted packages"
done


# ---------------------------------------------------------------------- #
#  Set file flags to skip unnecessary stage3+ builds and image exports
# ---------------------------------------------------------------------- #

print_header "SKIP and SKIP_IMAGES file flags"

# touch stage{3..5}/SKIP
# log "Set SKIP flag for stages 3 to 5"

find stage{2..5} -type f -name "EXPORT_*" -exec dirname {} \; | \
    uniq | \
    xargs -I{} touch {}/SKIP_IMAGES
log "Set SKIP_IMAGES flags for stages 2 to 5 where EXPORT_* flag exists"


# ---------------------------------------------------------------------- #
#  config-luaml
# ---------------------------------------------------------------------- #

print_header "config-luaml"

cat <<EOF >config-luaml
TIMEZONE="America/New_York"
ROOT_PASSWORD_LENGTH="22"
SALTSTACK_VERSION="stable 2017.7"
SALT_MASTER=""
EOF
log "Created local config-luaml file"


# ---------------------------------------------------------------------- #
#  Copy in stage2-luaml
# ---------------------------------------------------------------------- #

print_header "stage2-luaml"

if [[ -d /vagrant/src/pi-gen-stage2-luaml.d ]]; then
    rsync -crlptog --exclude .git /vagrant/src/pi-gen-stage2-luaml.d/ ./
fi
log "Copied in stage2-luaml dir tree"


# ---------------------------------------------------------------------- #
#  Custom *.deb files
# ---------------------------------------------------------------------- #

print_header "stage2-luaml/99-custom-deb-pkgs"

find /vagrant/src -type d -iname debian -exec dirname {} \; | \
    while read debdir; do
        info "dpkg-deb bulid for ..." "${debdir}"
        fakeroot dpkg-deb -b "${debdir}"
        if [[ $? -ne 0 ]]; then
            warn "The dpkg-deb build returned $?"
        else
            log "The dpkg-deb build returned $?"
        fi
    done

log "Copying *.deb packages to destination ..."
cp -v /vagrant/src/*.deb stage2-luaml/99-custom-deb-pkgs/files/


# ---------------------------------------------------------------------- #
#  END                                                                   #
# ---------------------------------------------------------------------- #

print_header "END"
