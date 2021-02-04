#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: read file and parse configurations
#      $1 <PATH>
#      $2 <IDENTIFIER> (array: parameters)
#      $3 <IDENTIFIER> (array: pass values to it)
#return: $?
function parseconfigs() {
  shopt -s extglob
  eval "local opts=(\${${2}[@]})"
  for opt in ${opts[@]}; do
    eval "local val=\$(grep -Ei '^[[:space:]]*${opt}[[:space:]]*=' '${1}' \
      | awk -F'=[[:space:]]*' '{printf \$2}')"
    if [[ "${val}" =~ ^\"([^\"]*)\"|^\'([^\']*)\'|^\`([^\`]*)\` ]]; then
      val="${BASH_REMATCH[1]:-${val}}"
      val="${BASH_REMATCH[2]:-${val}}"
      val="${BASH_REMATCH[3]:-${val}}"
    else
      val="${val%%+([[:space:]])#*}"
    fi
    eval "${3}['${opt}']='${val}'"
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
        if [[ ${#INSTANCES[@]} == 0 ]]; then
          INSTANCES=( "${arg}" )
        else
          INSTANCES=( "${INSTANCES[@]}" "${arg}" )
        fi
        ;;
    esac
  done
}

#Func: do initial configurations
#return: $?
function initconfig() {
  :
}

# vim: et:ts=2:sts:sw=2
