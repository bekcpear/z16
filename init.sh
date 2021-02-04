#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

if [[ -e "${CONFPATH}" ]]; then
  return
fi

# make z16rc
#
declare -A INIT_VARS
eval "INIT_VARS[${D_VARS_Z16[0]}_C]='The directory to store instances'"
eval "INIT_VARS[${D_VARS_Z16[0]}]=\${D_${D_VARS_Z16[0]}}"
eval "INIT_VARS[${D_VARS_Z16[1]}_C]='The global configuration file name of instances'"
eval "INIT_VARS[${D_VARS_Z16[1]}]=\${D_${D_VARS_Z16[1]}}"

echo ">> Initial z16"
for (( idx = 0; idx < ${#D_VARS_Z16[@]}; ++idx )); do
  eval "echo -e \"\e[2m| # \${INIT_VARS[${D_VARS_Z16[idx]}_C]}\e[0m\""
  eval "echo -e \"\e[2m|\e[0m set \e[96m\e[1m${D_VARS_Z16[idx]}\e[0m \
\e[2m(default: \${INIT_VARS[${D_VARS_Z16[idx]}]})\e[0m\""
  echo -en "       \e[2m<leave empty to use default>\e[0m\e[G"
  echo -en "\e[2m|\e[0m"
  read -ep ' to: ' INIT_TMP
  if [[ ${INIT_TMP//[[:space:]]/} != '' ]]; then
    eval "INIT_VARS[${D_VARS_Z16[idx]}]='${INIT_TMP}'"
  fi
done

eval "echo \"# This is the main configuration file of z16.
#
\" > '${CONFPATH}'"
for (( idx = 0; idx < ${#D_VARS_Z16[@]}; ++idx )); do
  eval "echo \"# \${INIT_VARS[${D_VARS_Z16[idx]}_C]}\" >> '${CONFPATH}'"
  eval "echo \"${D_VARS_Z16[idx]} = \${INIT_VARS[${D_VARS_Z16[idx]}]}\" >> '${CONFPATH}'"
  eval "echo \"\" >> '${CONFPATH}'"
done
echo "** written to ${CONFPATH}"

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

for (( idx = 0; idx < ${#D_VARS_G[@]}; ++idx )); do
  eval "echo -e \"\e[2m| # \${INIT_VARS[${D_VARS_G[idx]}_C]}\e[0m\""
  eval "echo -e \"\e[2m|\e[0m set \e[96m\e[1m${D_VARS_G[idx]}\e[0m \
\e[2m(default: \${INIT_VARS[${D_VARS_G[idx]}]})\e[0m\""
  echo -en "       \e[2m<leave empty to use default>\e[0m\e[G"
  echo -en "\e[2m|\e[0m"
  read -ep ' to: ' INIT_TMP
  if [[ ${INIT_TMP//[[:space:]]/} != '' ]]; then
    eval "INIT_VARS[${D_VARS_G[idx]}]='${INIT_TMP}'"
  fi
done

eval "GOLCONFPATH=\"\${INIT_VARS[${D_VARS_Z16[0]}]%/}/\${INIT_VARS[${D_VARS_Z16[1]}]}\""
eval "echo \"# This is the golbal configuration file of instances.
#
\" > '${GOLCONFPATH}'"
for (( idx = 0; idx < ${#D_VARS_G[@]}; ++idx )); do
  eval "echo \"# \${INIT_VARS[${D_VARS_G[idx]}_C]}\" >> '${GOLCONFPATH}'"
  eval "echo \"${D_VARS_G[idx]} = \${INIT_VARS[${D_VARS_G[idx]}]}\" >> '${GOLCONFPATH}'"
  eval "echo \"\" >> '${GOLCONFPATH}'"
done
echo "** written to ${GOLCONFPATH}"

echo "== Initialized."
# vim: et:ts=2:sts:sw=2
