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
  local -i ret=0
  shopt -s extglob
  eval "local opts=(\${${2}[@]})"
  for opt in ${opts[@]}; do
    [[ -d ${1%/*} ]] || ret+=$?
    local val
    eval "val=\$(grep -Ei '^[[:space:]]*${opt}[[:space:]]*=' '${1}' 2>${VERBOSEOUT2}) || true"
    eval "val=\$(echo '${val}' | awk -F'=[[:space:]]*' '{printf \$2}') || ret+=\$?"
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
  return ${ret}
}

#Func: parse shell parameters
#      $@
function parseparam() {
  set +e
  unset GETOPT_COMPATIBLE
  getopt -T
  if [[ ${?} != 4 ]]; then
    fatalerr "The command 'getopt' of Linux version is necessory to parse parameters."
  fi
  local args
  args=$(getopt -o 'vc:' -l 'verbose,config:' -n 'z16' -- "$@")
  if [[ ${?} != 0 ]]; then
    showhelp
    exit 1
  fi
  set -e
  eval "set -- ${args}"
  while true; do
    case "${1}" in
      -v|--verbose)
        VERBOSEOUT1='&1'
        VERBOSEOUT2='&2'
        shift
        ;;
      -c|--config)
        shift
        CONFPATH="${1}"
        shift
        ;;
      --)
        shift
        break
        ;;
      *)
        fatalerr "unknow error"
        ;;
    esac
  done
  local cmd
  local avacmd=( ${AVAILABLECMD//|/ } ${AVAILABLECMD_NOARGS//|/ } )
  for cmd in ${avacmd[@]}; do
    if [[ "${cmd}" == "${1}" ]]; then
      CMD=${1}
      shift
      break
    fi
  done
  if [[ ${CMD} =~ ${AVAILABLECMD} && ${#} < 1 ]]; then
    fatalerr "Action '${CMD}' needs more arguments!" True
  fi
  if [[ ${CMD} =~ ${AVAILABLECMD_NOARGS} && ${#} > 0 ]]; then
    eval "printlog 'arguments \"${@}\" ignored' warn"
    return
  fi
  for arg; do
    case "${arg}" in
      -*)
        printlog "Unrecognized instance name '${arg}' has been ignored." warn
        ;;
      *[[:space:]]*)
        fatalerr "Instance name should not contain spaces!"
        ;;
      */*)
        fatalerr "Instance name should not contain slashes!"
        ;;
      *)
        if [[ ${#INSTANCES[@]} == 0 ]]; then
          INSTANCES=( "${arg}" )
        else
          [[ "${INSTANCES[@]}" =~ (^|[[:space:]])${arg}([[:space:]]|$) ]] || \
          INSTANCES=( "${INSTANCES[@]}" "${arg}" )
        fi
        ;;
    esac
  done
}

# vim: et:ts=2:sts:sw=2
