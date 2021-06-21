#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: config instance #TODO
#      $1:
#      $2:
#      $3:
GCONFIGS_PRINTED=0
function config() {
  if [[ ${GCONFIGS_PRINTED} == 0 ]]; then
    GCONFIGS_PRINTED=1
    printlog "Now only show configurations!" warn
    printlog "  Global configurations:" conf
    declare -p CONFIGS
    printlog "  Ignored patterns:" conf
    declare -p IGNORES
    printlog "  SSH configurations:" conf
    declare -p Z16_SSH
    printlog "  SSH host informations:" conf
    _showsshinfo
  fi

  printlog "  Instance '${INSTANCES[${3}]}' configurations:" conf
  eval "declare -p CONFIGS_${3}"
  printlog "  Instance '${INSTANCES[${3}]}' ignored patterns:" conf
  eval "declare -p IGNORES_${3}"
  _get_igno ${3}
  echo
}

# vim: et:ts=2:sts:sw=2
