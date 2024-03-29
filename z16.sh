#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

# Dependencies:
#
#  * sys-apps/coreutils
#  |-- chown
#  |-- chmod
#  |-- cp
#  |-- date
#  |-- echo
#  |-- id
#  |-- ln
#  |-- ls
#  |-- mkdir
#  |-- readlink (GNU version)
#  |-- realpath
#  |-- rmdir
#  |-- touch
#  `-- unlink
#
#  * sys-apps/grep
#  `-- grep
#
#  * sys-apps/util-linux
#  `-- getopt (Linux version)
#
#  * sys-libs/glibc
#  `-- getent
#
#  * net-misc/openssh [optional]
#  |-- scp
#  `-- ssh

# paramaters:
#             commands: init|load|fetch|unload|config|list|help
#     optional options: --/-OPT VALUE !!!TODO
#             argument: [(<INSTANCE NAME>)]

# file structure:
#   <MAIN-FOLDER>
#     |-- .z16.g.conf (global configuration file)
#     |-- <INSTANCE-NAME-0>
#           |-- .z16.l.conf (default name)
#           |-- <FILE/DIRECTORY>
#           |   # support prefixed with `dot-` instead of `.`
#           `-- ...
#     |-- <INSTANCE-NAME-1>
#     |-- <INSTANCE-NAME-2>
#     `-- ...

#
# TODO: merge specified path
# TODO: remove unlinked links when loading instances
# TODO: rename instance
# TODO: generate instances through a path list file and restore
# TODO: database of loaded instances
# TODO: about SUID/SGID
# TODO: SELinux support
#
#

set +abfhkmnptuvBCEHPT
set -Beh

AVAILABLECMD="init|config|load|fetch|unload"
AVAILABLECMD_NOARGS="list|help"
declare -a INSTANCES
declare -A CONFIGS
declare -a IGNORES
CMD='help'

#READONLY VARIABLE
declare -r Z16_TMPDIR='/tmp/.z16_tmpdir_de82969a-064c-43d7-b761-6061eb1669f8'
Z16_OWSP_P='_bd3c8c_z16_ownership'
#DEFAULT VARIABLES THAT CAN ONLY BE MODIFIED BY COMMAND LINE OPTION
FORCEOVERRIDE=0
PRETEND=0
Z16_SSH_RAW=
declare -A Z16_SSH=([IDENTITYOPTS]="" [USER]="" [HOSTNAME]="" [PORT]=22 [MUX_TIMEOUT]=600 [KEEP]=0)
VERBOSEOUT1=/dev/null
VERBOSEOUT2=/dev/null
declare -r SYSCONFPATH="/etc/z16/z16rc"
CONFPATH="${HOME%/}/.config/z16/z16rc"
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
  IGNORE
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

CUSER=
CGROUP=
CGROUPS=

SPATH="${0}"
if [[ -L "${SPATH}" ]]; then
  eval "SPATH=\$(realpath '${SPATH}')"
fi
source "${SPATH%/*}"/meta.sh
source "${SPATH%/*}"/helper.sh
source "${SPATH%/*}"/parse.sh
source "${SPATH%/*}"/main.sh

# parse shell parameters
#
parseparam "$@"

# do initialize configurations
#
source "${SPATH%/*}"/initZ16.sh

# parse shell configurations
#
function _mkvarnotempty() {
  local -i idx
  for (( idx = 0; idx < ${#D_VARS_Z16[@]}; ++idx )); do
    eval "CONFIGS[${D_VARS_Z16[idx]}]=\${CONFIGS[${D_VARS_Z16[idx]}]:-\${D_${D_VARS_Z16[idx]}}}"
  done
}
if [[ -e "${SYSCONFPATH}" ]]; then
  parseconfigs "${SYSCONFPATH}" D_VARS_Z16 _ CONFIGS
  _mkvarnotempty
fi
if [[ -e "${CONFPATH}" ]]; then
  parseconfigs "${CONFPATH}" D_VARS_Z16 _ CONFIGS
  _mkvarnotempty
fi
eval "CONFIGS[${D_VARS_Z16[0]}]=\$(_absolutepath '${CONFIGS[${D_VARS_Z16[0]}]}')"
_fatalunsupportedpath "${CONFIGS[${D_VARS_Z16[0]}]}"

set +e
# parse instance global configurations
#
parseconfigs "${CONFIGS[${D_VARS_Z16[0]}]%/}/${CONFIGS[${D_VARS_Z16[1]}]#/}" D_VARS_G IGNORES CONFIGS
if [[ ${?} != 0 ]]; then
  printlog "You may not configure correctly." warn
  fatalerr "Parse global configurations failed!"
fi
for (( idx = 0; idx < ${#D_VARS_G[@]}; ++idx )); do
  eval "CONFIGS[${D_VARS_G[idx]}]=\${CONFIGS[${D_VARS_G[idx]}]:-\${D_${D_VARS_G[idx]}}}"
done

if [[ ${CMD} =~ ${AVAILABLECMD} && ${CMD} != init ]]; then
  # parse instance local configurations
  #
  for (( idx = 0; idx < ${#INSTANCES[@]}; ++idx )); do
    eval "declare -A CONFIGS_${idx}"
    eval "declare -a IGNORES_${idx}"
    eval "parseconfigs \
      "${CONFIGS[${D_VARS_Z16[0]}]%/}"/"${INSTANCES[idx]}"/"${CONFIGS[${D_VARS_G[0]}]#/}" \
      D_VARS_L IGNORES_${idx} CONFIGS_${idx}"
    if [[ ${?} != 0 ]]; then
      printlog "You may need to initialize instances \"${INSTANCES[idx]}\" first." warn
      fatalerr "Parse configurations of \"${INSTANCES[idx]}\" failed."
    fi
  done
fi
set -e

# exec main commands
#
execmain

# vim: et:ts=2:sts:sw=2
