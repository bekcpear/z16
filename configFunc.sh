#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: read file and set configurations
#      $1 <PATH>
#      $2 <VARIABLE NAME> (array: parameters)
#      $3 <VARIABLE NAME> (array: pass values to it)
#return: $?
function setconfigs() {
  shopt -s extglob
  eval "local opts=(\${${2}[@]})"
  for opt in ${opts[@]}; do
    eval "local val=\$(grep -Ei '^[[:space:]]*${opt}[[:space:]]*=' '${1}' \
      | awk -F'=[[:space:]]*' '{printf \$2}')"
    val="${val%% #*}"
    eval "${3}['${opt}']='${val%%+([[:space:]])}'"
  done
  shopt -u extglob
}

#Func: parse shell parameters
#      $@
#retrun: $?
function parseparam() {
  CMD=${DEFAULTCMD}
  local cmd
  for cmd in ${AVAILABLECMD[@]}; do
    if [[ "${cmd}" == "${1}" ]]; then
      CMD=${1}
      shift
      break
    fi
  done
  for arg; do
    case "${arg}" in
      -*)
        # OPT - VALUE!!!TODO
        ;;
      *[[:space:]]*)
        fatalerr "Instance name should not contain spaces!"
        ;;
      *)
        if [[ ${INSTANCE} == '' ]]; then
          INSTANCE="${arg}"
        else
          INSTANCE=( "${INSTANCE[@]}" "${arg}" )
        fi
        ;;
    esac
  done
}

# vim: et:ts=2:sts:sw=2
