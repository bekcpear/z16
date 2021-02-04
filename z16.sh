#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

# commands:
#   ln
#   unlink
#   grep
#   awk

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
#  #create the link by which user
#   operator: <username>
#  #the link owner
#   owner: <username>
#  #the link group
#   group: <groupname>
#  #default umask
#   umask: 022

set -e

#TODO: check identifier conflict
AVAILABLECMD=(init list load unload config help)
declare -a INSTANCES
declare -A CONFIGS
CMD=

#DEFAULT READONLY VARIABLES
D_CMD='help'
#DEFAULT VARIABLES THAT CAN ONLY BE MODIFIED BY COMMAND LINE OPTION
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
  OPERATOR
  USER
  GROUP
  UMASK
)
D_VARS_G=(
  INSTLOCALCONFNAME
  ${D_VARS_L[@]}
)
eval "D_${D_VARS_G[0]}='.z16.l.conf'"
eval "D_${D_VARS_G[1]}='/tmp/z16.tmp.d'"
eval "D_${D_VARS_G[2]}=''"
eval "D_${D_VARS_G[3]}=''"
eval "D_${D_VARS_G[4]}=''"
eval "D_${D_VARS_G[5]}='022'"

eval ""

source "${0%/*}"/parseFuncs.sh
source "${0%/*}"/helperFuncs.sh
source "${0%/*}"/mainFuncs.sh

# parse shell parameters
#
parseparam "$@"

# do initial configurations
#
source "${0%/*}"/init.sh
exit

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

# parse instance local configurations
#
for (( idx = 0; idx < ${#INSTANCES[@]}; ++idx )); do
  eval "declare -A CONFIGS_${idx}"
  eval "parseconfigs \
    "${CONFIGS[${D_VARS_Z16[0]}]%/}"/"${INSTANCES[idx]}"/"${CONFIGS[${D_VARS_G[0]}]#/}" \
    D_VARS_L CONFIGS_${idx}"
done

# exec main commands
#
execmain

# test out
#
declare -p CONFIGS
declare -p CONFIGS_0
#set

# vim: et:ts=2:sts:sw=2
