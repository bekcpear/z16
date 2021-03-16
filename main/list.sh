#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: list instance
#    [$1]: instance name(s) #TODO: more details and show configurations
#return: $?
function list() {
  local -a lists
  eval "lists=( \$(ls -1 \${CONFIGS[${D_VARS_Z16[0]}]}) )"
  local i
  for (( i = 0; i < ${#lists[@]}; ++i )); do
    [[ -d "${CONFIGS[${D_VARS_Z16[0]}]%/}/${lists[i]}" ]] || continue
    echo ${lists[i]}
  done
}

# vim: et:ts=2:sts:sw=2
