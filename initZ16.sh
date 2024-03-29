#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

if [[ -e "${CONFPATH}" || -e "${SYSCONFPATH}" ]]; then
  return
fi

declare -A INIT_VARS

#Func: customize variables
#      $1 variable name
#      $2 the count of variable elements
function _init_customizevar() {
  local -i idx
  for (( idx = 0; idx < ${2}; ++idx )); do
    eval "echo \"\${INIT_VARS[\${${1}[idx]}_C]}\"" | \
    while read -r comment; do
      echo -e "\e[2m| # ${comment}\e[0m"
    done
    eval "echo -e \"\e[2m|\e[0m set \e[96m\e[1m\${${1}[idx]}\e[0m \
\e[2m(default: \${INIT_VARS[\${${1}[idx]}]})\e[0m\""
    echo -en "       \e[2m<leave empty to use default>\e[0m\e[G"
    echo -en "\e[2m|\e[0m"
    read -rep ' to: ' INIT_TMP
    if [[ ${INIT_TMP//[[:space:]]/} != '' ]]; then
      eval "INIT_VARS[\${${1}[idx]}]='${INIT_TMP}'"
    fi
  done
}

#Func: write configurations to file
#      $1 variable name
#      $2 the count of variable elements
#      $3 the path of the configuration file
#      $4 the description of the file
function _init_writevar() {
  local -i idx
  local p="${3}"
  [[ -e "${p%/*}" ]] || mkdir -p "${p%/*}"
  eval "echo \"# ${4}
#
\" > '${p}'"
  for (( idx = 0; idx < ${2}; ++idx )); do
    eval "while read -r comment; do
      echo \"# \${comment}\" >> '${p}'
    done <<< \"\${INIT_VARS[\${${1}[idx]}_C]}\""
    eval "echo \"${mask}\${${1}[idx]} =\
\${INIT_VARS[\${${1}[idx]}]:+ }\${INIT_VARS[\${${1}[idx]}]}\" >> '${p}'"
    eval "echo \"\" >> '${p}'"
  done
  printlog "** Have been written to '${p}'" stage
}

# make z16rc
#
eval "INIT_VARS[${D_VARS_Z16[0]}_C]='The directory to store instances, absolute path'"
eval "INIT_VARS[${D_VARS_Z16[0]}]=\${D_${D_VARS_Z16[0]}}"
eval "INIT_VARS[${D_VARS_Z16[1]}_C]='The global configuration file name of instances'"
eval "INIT_VARS[${D_VARS_Z16[1]}]=\${D_${D_VARS_Z16[1]}}"
echo ">> Initialize z16"
_init_customizevar D_VARS_Z16 ${#D_VARS_Z16[@]}
_init_writevar D_VARS_Z16 ${#D_VARS_Z16[@]} "${CONFPATH}" "This is the main configuration file of z16."

# make global configuration file of instances
#
echo ">> Create global congiguration file of instances"
eval "INIT_VARS[${D_VARS_G[0]}_C]='The local configuration file name of the instance'"
eval "INIT_VARS[${D_VARS_G[0]}]=\${D_${D_VARS_G[0]}}"
eval "INIT_VARS[${D_VARS_G[1]}_C]='The parent folder path of the instance, absolute path'"
eval "INIT_VARS[${D_VARS_G[1]}]=\${D_${D_VARS_G[1]}}"
eval "INIT_VARS[${D_VARS_G[2]}_C]='The owner of the symbolic links and their targets'"
eval "INIT_VARS[${D_VARS_G[2]}]=\${D_${D_VARS_G[2]}}"
eval "INIT_VARS[${D_VARS_G[3]}_C]='The group of the symbolic links and their targets'"
eval "INIT_VARS[${D_VARS_G[3]}]=\${D_${D_VARS_G[3]}}"
eval "INIT_VARS[${D_VARS_G[4]}_C]='Ignored file patterns which are seperated by commas.
Every pattern is a POSIX extended regular expression, and
should include the path relative to the instance directory.'"
eval "INIT_VARS[${D_VARS_G[4]}]=\${D_${D_VARS_G[4]}}"
_init_customizevar D_VARS_G ${#D_VARS_G[@]}
eval "GOLCONFPATH=\"\${INIT_VARS[${D_VARS_Z16[0]}]%/}/\${INIT_VARS[${D_VARS_Z16[1]}]}\""
eval "GOLCONFPATH=\$(_absolutepath '${GOLCONFPATH}')"
_init_writevar D_VARS_G ${#D_VARS_G[@]} "${GOLCONFPATH}" "This is the golbal configuration file of instances."

echo "== Initialized."
# vim: et:ts=2:sts:sw=2
