#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: read file and parse configurations
#      $1 <PATH>
#      $2 <IDENTIFIER> (array: parameters)
#      $3 <IDENTIFIER> (array: ignored list)
#      $4 <IDENTIFIER> (array: pass values to it)
#return: $?
function parseconfigs() {
  local p="${1}"
  local -i ret=0
  shopt -s extglob
  eval "local opts=(\${${2}[@]})"
  eval "p=\$(_absolutepath '${p}')"
  for opt in ${opts[@]}; do
    if [[ ! -d ${p%/*} ]]; then
      printlog "Directory '${1%/*}' does not exist." warn
      ret+=1
    fi
    local val
    eval "val=\$(grep -Ei '^[[:space:]]*${opt}[[:space:]]*=' '${p}' 2>${VERBOSEOUT2}) || true"
    eval "val=\$(echo '${val}' | { IFS='='; read -r _ v; echo -n \"\${v}\"; }) || ret+=\$?"
    val=${val##[[:space:]]}
    if [[ "${val}" =~ ^\"([^\"]*)\"|^\'([^\']*)\'|^\`([^\`]*)\` ]]; then
      val="${BASH_REMATCH[1]:-${val}}"
      val="${BASH_REMATCH[2]:-${val}}"
      val="${BASH_REMATCH[3]:-${val}}"
    else
      val="${val%%+([[:space:]])#*}"
    fi
    if [[ "${opt}" == IGNORE ]]; then
      #parse ignore patterns
      if [[ -n ${val} ]]; then
        local -i nn=0
        val="${val//\\/\\\\}"
        val="${val//\\,/Z16CoMmA-f09448b9-96c6-4f09-8b6f-bb7d5c251943}"
        val="${val//,/$'\n'}"
        val="${val//Z16CoMmA-f09448b9-96c6-4f09-8b6f-bb7d5c251943/\\,}"
        while read -r n; do
          eval "${3}[${nn}]=\"${n}\""
          (( ++nn ))
        done <<< "${val}"
      fi
    else
      eval "${4}['${opt}']='${val}'"
    fi
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
  args=$(getopt -o 'P:c:fi:k::ps:v' -l 'port:,config:,force,identity-file:,keep-alive::,pretend,ssh-destination:,verbose' -n 'z16' -- "$@")
  if [[ ${?} != 0 ]]; then
    showhelp
    exit 1
  fi
  set -e

  # parse arguments
  eval "set -- ${args}"
  while true; do
    case "${1}" in
      -P|--port)
        shift
        if [[ ${1} =~ ^[[:digit:]]+$ ]]; then
          Z16_SSH[PORT]=${1}P
        else
          printlog "Unrecognized ssh port: '${1}', use default '${Z16_SSH[PORT]}' instead." warn
        fi
        shift
        ;;
      -c|--config)
        shift
        CONFPATH="${1}"
        shift
        ;;
      -f|--force)
        FORCEOVERRIDE=1
        shift
        ;;
      -i|--identity-file)
        shift
        Z16_SSH[IDENTITYOPTS]+="-i '${1}' "
        shift
        ;;
      -k|--keep-alive)
        shift
        Z16_SSH[KEEP]=1
        if [[ ${1} =~ ^[[:digit:]]+(s|S|m|M|h|H|d|D|w|W)?$ ]]; then
          Z16_SSH[MUX_TIMEOUT]=${1}
        elif [[ -n ${1} ]]; then
          printlog "Unrecognized timeout argument: '${1}', use default '${Z16_SSH[MUX_TIMEOUT]}' instead." warn
        fi
        shift
        ;;
      -p|--pretend)
        PRETEND=1
        shift
        ;;
      -s|--ssh-destination)
        shift
        Z16_SSH_RAW="${1}"
        shift
        ;;
      -v|--verbose)
        VERBOSEOUT1='&1'
        VERBOSEOUT2='&2'
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

  # check action
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
    eval "printlog 'args: \"${@}\" ignored' warn"
    return
  fi

  # parse instance name
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

  # check ssh configurations and unify
  if [[ -n ${Z16_SSH_RAW} ]]; then
    local sshconfraw _idfpath
    eval "sshconfraw=\"\$(ssh ${Z16_SSH[IDENTITYOPTS]} -G ${Z16_SSH_RAW})\"" || \
      fatalerr "Get SSH configurations error!" $?
    while read -r line; do
      case "${line}" in
        user*)
          Z16_SSH[USER]="${line#* }"
          ;;
        hostname*)
          Z16_SSH[HOSTNAME]="${line#* }"
          ;;
        port*)
          if [[ ! ${Z16_SSH[PORT]} =~ P$ ]]; then
            Z16_SSH[PORT]="${line#* }"
          fi
          ;;
        identityfile*)
          if [[ -z ${Z16_SSH[IDENTITYOPTS]} ]]; then
            _idfpath=$(_absolutepath ${line#* })
            if [[ -e ${_idfpath} ]]; then
              Z16_SSH[IDENTITYOPTS]+="-i '${_idfpath}' "
            fi
          fi
          ;;
      esac
    done <<< "$(echo "${sshconfraw}" | grep -E '^user\s|^hostname\s|^port\s|^identityfile\s')"
    if [[ ${Z16_SSH[PORT]} =~ P$ ]]; then
      Z16_SSH[PORT]="${Z16_SSH[PORT]%P}"
    fi
  fi
}

# vim: et:ts=2:sts:sw=2
