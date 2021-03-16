#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: init instance
#      $1: instance name(s)
#return: $?
function init() {
  local -a insts
  for inst; do
    local cpath
    eval "cpath=\"\${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst%/}/\${CONFIGS[${D_VARS_G[0]}]}\""
    if [[ -e "${cpath}" ]]; then
      #TODO: check file type
      continue
    else
      set +e
      local -i ret=0
      mkdir -p "${cpath%/*}" || ret+=$?
      touch "${cpath}" || ret+=$?
      local varname
      for varname in "${D_VARS_L[@]}"; do
        echo "# ${varname} =" >> "${cpath}" || ret+=$?
      done
      insts=( "${insts[@]}" "${inst}" )
      set -e
      if [[ ${ret} > 0 ]]; then
        fatalerr "Initialize instance '${inst}' failed!"
      fi
    fi
    #TODO: more detailed configurations.
  done
  if [[ ${#insts[@]} > 0 ]]; then
    local inststr i
    for (( i = 0; i < ${#insts[@]}; ++i )); do
      inststr="${inststr}, '${insts[i]}'"
    done
    printlog "== Instance: ${inststr#, } initialized." stage
  else
    printlog "Nothing needs to be initialized!" warn
  fi
}

# vim: et:ts=2:sts:sw=2
