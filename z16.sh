#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

# commands:
#   date
#   eval
#   ln
#   unlink
#   grep
#   awk
#   mkdir
#   getopt <Linux VERSION>
#   readlink <GNU VERSION>
#   chown

# paramaters:
#     optional command: init|load|unload|config|help
#     optional options: --/-OPT VALUE !!!TODO
#   necessary argument: <INSTANCE NAME>

# file structure:
#   <MAIN-FOLDER>
#     |-- .z16.g.conf (global configuration file)
#     |-- <INSTANCE-NAME-0>
#           |-- .z16.l.conf (default name)
#           |-- <FILE/DIRECTORY>
#           |   # support prefixed with `dot-` instead of `.`
#           |-- ...
#     |-- <INSTANCE-NAME-1>
#     |-- <INSTANCE-NAME-2>
#     |-- ...

# about configiguration file, .z16.l.conf:
#  #parent folder path for the symbolic link
#   parent: <path> (default to /tmp/z16.tmp.d for safety)
#  #the link owner
#   owner: <username>
#  #the link group
#   group: <groupname>
#  #default umask
#   umask: 022

set +abfhkmnptuvBCEHPT
set -Beh

#TODO: check identifier conflict
AVAILABLECMD="init|config|load|unload"
AVAILABLECMD_NOARGS="list|help"
declare -a INSTANCES
declare -a PATH_STACK
declare -A CONFIGS
CMD='help'
CUSER="$(id -nu)"
CGROUP="$(id -ng)"

#READONLY VARIABLE
declare -r Z16_TMPDIR='/tmp/.z16_tmpdir_de82969a-064c-43d7-b761-6061eb1669f8'
#DEFAULT VARIABLES THAT CAN ONLY BE MODIFIED BY COMMAND LINE OPTION
VERBOSEOUT1=/dev/null
VERBOSEOUT2=/dev/null
CONFPATH="${HOME%/}/.config/z16rc"
#DEFAULT VARIABLES
D_VARS_Z16=(
  INSTDIR
  INSTGLOBALCONFNAME
)
eval "D_${D_VARS_Z16[0]}='${HOME%/}/.local/share/z16'"
eval "D_${D_VARS_Z16[1]}='.z16.g.conf'"
D_VARS_L=(
  PARENTDIR
  USER
  GROUP
)
D_VARS_G=(
  INSTLOCALCONFNAME
  ${D_VARS_L[@]}
)
eval "D_${D_VARS_G[0]}='.z16.l.conf'"
eval "D_${D_VARS_G[1]}='/tmp/z16.tmp.d'"
eval "D_${D_VARS_G[2]}=''"
eval "D_${D_VARS_G[3]}=''"

source "${0%/*}"/parseFuncs.sh
source "${0%/*}"/helperFuncs.sh
source "${0%/*}"/mainFuncs.sh

# parse shell parameters
#
parseparam "$@"

# do initial configurations
#
source "${0%/*}"/init.sh

# do some check
#
check

# parse shell configurations
#
parseconfigs "${CONFPATH}" D_VARS_Z16 CONFIGS
for (( idx = 0; idx < ${#D_VARS_Z16[@]}; ++idx )); do
  eval "CONFIGS[${D_VARS_Z16[idx]}]=\${CONFIGS[${D_VARS_Z16[idx]}]:=\${D_${D_VARS_Z16[idx]}}}"
done

# parse instance global configurations
#
parseconfigs "${CONFIGS[${D_VARS_Z16[0]}]%/}/${CONFIGS[${D_VARS_Z16[1]}]#/}" D_VARS_G CONFIGS
for (( idx = 0; idx < ${#D_VARS_G[@]}; ++idx )); do
  eval "CONFIGS[${D_VARS_G[idx]}]=\${CONFIGS[${D_VARS_G[idx]}]:=\${D_${D_VARS_G[idx]}}}"
done

set +e
if [[ ${CMD} =~ ${AVAILABLECMD} && ${CMD} != init ]]; then
  # parse instance local configurations
  #
  for (( idx = 0; idx < ${#INSTANCES[@]}; ++idx )); do
    eval "declare -A CONFIGS_${idx}"
    eval "parseconfigs \
      "${CONFIGS[${D_VARS_Z16[0]}]%/}"/"${INSTANCES[idx]}"/"${CONFIGS[${D_VARS_G[0]}]#/}" \
      D_VARS_L CONFIGS_${idx}"
    if [[ ${?} != 0 ]]; then
      printlog "you may need to initialize instances \"${INSTANCES[idx]}\" first." warn
      fatalerr "parse configurations of \"${INSTANCES[idx]}\" failed."
    fi
  done
fi
set -e
# exec main commands
#
execmain

exit
# test out
#
declare -p CONFIGS
declare -p CONFIGS_0
declare -p CONFIGS_1
declare -p CONFIGS_2
#set

# vim: et:ts=2:sts:sw=2
