# =====================================================================
#
# ANSI Color Codes
#
# =====================================================================

START='\e[1m'
END='\e[0m'

#BLACK='\e[0;30m'
#BOLDBLACK='\e[1;30m'
#HIBLACK='\e[0;90m'
#BOLDHIBLACK='\e[1;90m'

RED='\e[0;31m'
BOLDRED='\e[1;31m'
HIRED='\e[0;91m'
BOLDHIRED='\e[1;91m'

GREEN='\e[0;32m'
BOLDGREEN='\e[1;32m'
HIGREEN='\e[0;92m'
BOLDHIGREEN='\e[1;92m'

YELLOW='\e[0;33m'
BOLDYELLOW='\e[1;33m'
HIYELLOW='\e[0;93m'
BOLDHIYELLOW='\e[1;93m'

CYAN='\e[0;34m'
BOLDCYAN='\e[1;34m'
HIBLUE='\e[0;94m'
BOLDHIBLUE='\e[1;94m'

#PURPLE='\e[0;35m'
#BOLDPURPLE='\e[1;35m'; 
#HIPURPLE='\e[0;95m'
#BOLDHIPURPLE='\e[1;95m'

CYAN='\e[0;36m'
BOLDCYAN='\e[1;36m'
HICYAN='\e[0;96m'
BOLDHICYAN='\e[1;96m'

WHITE='\e[0;37m'
BOLDWHITE='\e[1;37m'
HIWHITE='\e[0;97m'
BOLDHIWHITE='\e[1;97m'


# =====================================================================
#
# Logging Functions
#
# =====================================================================

function info () {
  local _key="$1"
  local _value="$2"
  echo -en '['${START}${BOLDCYAN}'INFO '${END}']: '
  echo -en ${WHITE}
  printf "%-30s : " "${_key}"
  echo -en ${END}
  echo -e ${BOLDWHITE}${START}"${_value}"${END}
}

function log () {
  echo -e '['${START}${BOLDGREEN}'LOG'${END}'  ]: '${WHITE}"$*"${END}
}

function warn () {
  echo -e '['${START}${BOLDYELLOW}'WARN'${END}' ]: '${WHITE}"$*"${END}
}

function error () {
  echo -e '['${START}${BOLDRED}'ERROR'${END}']: '${START}${BOLDHIRED}"$*"${END}
}

function debug () {
  echo -e '['${START}${BOLDHIWHITE}'DEBUG'${END}']: '${START}${WHITE}"$*"${END}
}

function error_and_exit () {
  error "$*"
  exit 1
}

function print_header () {
  # 
  # ├─┤ HEADER TEXT ├──────────────────────────────────────┤
  # 
  local _header="$(echo "$*" | tr 'a-z' 'A-Z')"
  local _width=$(( $(tput cols) - "${#1}" - 7 ))
  echo -e '\n'
  echo -en ${START}${WHITE}
  echo -n $'\u251c\u2500\u2524 '         # ├─┤
  echo -en ${END}
  echo -en ${START}${BOLDHICYAN}"${_header}"${END}
  echo -en ${START}${WHITE}
  echo -n $' \u251c'                     # ├
  eval printf $'%.0s\u2500' {1..$_width} #  ──
  echo -n $'\u2524'                      #    ┤
  echo -en ${END}
  echo -e '\n'
}

