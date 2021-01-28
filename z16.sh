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

AVAILABLECMD=(init list load unload config help)
INSTANCE=''
declare -A CONFIGS
CMD=''

#DEFAULT READONLY VARIABLES
DEFAULT_CMD='help'
#DEFAULT VARIABLES THAT CAN ONLY BE MODIFIED BY COMMAND LINE OPTION
Z16_CONFPATH="${HOME%/}/.config/z16rc"
#DEFAULT VARIABLES
DEFAULT_VARS_Z16=(
  INSTGLOBALCONFNAME
  PROJDIR
)
eval "DEFAULT_${DEFAULT_VARS_Z16[0]}='.z16.g.conf'"
eval "DEFAULT_${DEFAULT_VARS_Z16[1]}='${HOME%/}/.local/share/z16'"
DEFAULT_VARS_L=(
  PARENTDIR
  OPERATOR
  USER
  GROUP
  UMASK
)
DEFAULT_VARS_G=(
  INSTLOCALCONFNAME
  ${DEFAULT_VARS_L[@]}
)
eval "DEFAULT_${DEFAULT_VARS_G[0]}='.z16.l.conf'"
eval "DEFAULT_${DEFAULT_VARS_G[1]}='/tmp/z16.tmp.d'"
eval "DEFAULT_${DEFAULT_VARS_G[2]}=''"
eval "DEFAULT_${DEFAULT_VARS_G[3]}=''"
eval "DEFAULT_${DEFAULT_VARS_G[4]}=''"
eval "DEFAULT_${DEFAULT_VARS_G[5]}='022'"

source "${0%/*}"/configFunc.sh
source "${0%/*}"/helperFunc.sh
source "${0%/*}"/mainFunc.sh

parseparam "$@"
setconfigs "${Z16_CONFPATH}" DEFAULT_VARS_Z16 CONFIGS
execmain

declare -p CONFIGS

# vim: et:ts=2:sts:sw=2
