#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

if [[ -e "${CONFPATH}" ]]; then
  return
fi

declare -A INIT_VARS

#Func: customize variables
#      $1 variable name
#      $2 the count of variable elements
function customizevar() {
  for (( idx = 0; idx < ${2}; ++idx )); do
    eval "echo -e \"\e[2m| # \${INIT_VARS[\${${1}[idx]}_C]}\e[0m\""
    eval "echo -e \"\e[2m|\e[0m set \e[96m\e[1m\${${1}[idx]}\e[0m \
\e[2m(default: \${INIT_VARS[\${${1}[idx]}]})\e[0m\""
    echo -en "       \e[2m<leave empty to use default>\e[0m\e[G"
    echo -en "\e[2m|\e[0m"
    read -ep ' to: ' INIT_TMP
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
function writevar() {
  eval "echo \"# ${4}
#
\" > '${3}'"
  for (( idx = 0; idx < ${2}; ++idx )); do
    eval "echo \"# \${INIT_VARS[\${${1}[idx]}_C]}\" >> '${3}'"
    eval "echo \"\${${1}[idx]} = \${INIT_VARS[\${${1}[idx]}]}\" >> '${3}'"
    eval "echo \"\" >> '${3}'"
  done
  echo "** written to ${3}"
}


# make z16rc
#
eval "INIT_VARS[${D_VARS_Z16[0]}_C]='The directory to store instances'"
eval "INIT_VARS[${D_VARS_Z16[0]}]=\${D_${D_VARS_Z16[0]}}"
eval "INIT_VARS[${D_VARS_Z16[1]}_C]='The global configuration file name of instances'"
eval "INIT_VARS[${D_VARS_Z16[1]}]=\${D_${D_VARS_Z16[1]}}"
echo ">> Initial z16"
customizevar D_VARS_Z16 ${#D_VARS_Z16[@]}
writevar D_VARS_Z16 ${#D_VARS_Z16[@]} "${CONFPATH}" "This is the main configuration file of z16."

# prepare directory
#
echo ">> Prepare the directory of instances"
mkdir -p "${INIT_VARS[${D_VARS_Z16[0]}]}"
if [[ $? == 0 ]]; then
  echo "** directory of instances prepared."
fi

# make global configuration file of instance
#
echo ">> Create global congiguration file of instances"
eval "INIT_VARS[${D_VARS_G[0]}_C]='The local configuration file name of the instance'"
eval "INIT_VARS[${D_VARS_G[0]}]=\${D_${D_VARS_G[0]}}"
eval "INIT_VARS[${D_VARS_G[1]}_C]='The parent folder path of the instance'"
eval "INIT_VARS[${D_VARS_G[1]}]=\${D_${D_VARS_G[1]}}"
eval "INIT_VARS[${D_VARS_G[2]}_C]='The user that executes commands'"
eval "INIT_VARS[${D_VARS_G[2]}]=\${D_${D_VARS_G[2]}}"
eval "INIT_VARS[${D_VARS_G[3]}_C]='The owner of the symbolic links'"
eval "INIT_VARS[${D_VARS_G[3]}]=\${D_${D_VARS_G[3]}}"
eval "INIT_VARS[${D_VARS_G[4]}_C]='The group of the symbolic links'"
eval "INIT_VARS[${D_VARS_G[4]}]=\${D_${D_VARS_G[4]}}"
eval "INIT_VARS[${D_VARS_G[5]}_C]='The umask that should be used when creating symbolic links'"
eval "INIT_VARS[${D_VARS_G[5]}]=\${D_${D_VARS_G[5]}}"
customizevar D_VARS_G ${#D_VARS_G[@]}
eval "GOLCONFPATH=\"\${INIT_VARS[${D_VARS_Z16[0]}]%/}/\${INIT_VARS[${D_VARS_Z16[1]}]}\""
writevar D_VARS_G ${#D_VARS_G[@]} "${GOLCONFPATH}" "This is the golbal configuration file of instances."

echo "== Initialized."
# vim: et:ts=2:sts:sw=2
