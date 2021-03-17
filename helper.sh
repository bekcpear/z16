#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: show help informations
function showhelp() {
  echo "
Usage: z16 [<options>] <command> [(<instance>)]

options:
  -c, --config=FILE          Use this user-level configuration file instead of
                               the default ~/.config/z16/z16rc.
  -f, --force                Force override the destination.
  -i, --identity-file=FILE   Identity file of the SSH connection.
  -k, --keep-alive[=NUMBER]  Keep SSH multiplexing connection alive for optional
                               specified time (default to 600 seconds).
  -p, --pretend              Pretend to load/unload instances(temporary files
                               will be created anyway).
  -P, --port=NUMBER          Use this ssh port number instead of any others.
  -s, --ssh-destination=DEST SSH destination, the same format as the ssh command.
  -v, --verbose              Show more informations.

commands:
  init   (<instance>)        Initialize instance(s).
  load   (<instance>)        Create symbolic links to files of the instance(s).
  fetch  (<instance>)        !TODO, Fetch files according to the instance(s).
  unload (<instance>)        Remove symbolic links belonging to the instance(s).
  config (<instance>)        !TODO, Configure instance(s).
  list                       List all instances.
  help                       Show this help message.
"
}

#Func: print log
#      $1: msg  <STRING>
#    [$2]: type <stage|conf|warn|err> (default: info)
#retrun: $?
function printlog() {
  local type="${2:-info}"
  local color=
  local out=
  case "${type}" in
    info)
      type=" info"
      color="\e[0m"
      out="${VERBOSEOUT1}"
      ;;
    stage)
      type="stage"
      color="\e[0m"
      out="&1"
      ;;
    conf)
      type=" conf"
      color="\e[36m"
      out="&1"
      ;;
    warn)
      type=" warn"
      color="\e[33m"
      out="&2"
      ;;
    err)
      type="error"
      color="\e[31m"
      out="&2"
      ;;
  esac
  if [[ -n ${Z16_SSH[HOSTNAME]} ]]; then
    type+=" (SSH)"
  fi
  eval "echo -e \"${color}[$(date +%H:%M:%S) ${type}] ${1//\"/\\\"}\e[0m\" >${out}"
}

#Func: exit shell and print error
#      $1: msg              <STRING>
#    [$2]: show help or not <True|False> (default: False)
#          or return code
#return: $?
function fatalerr() {
  local ret=1
  printlog "${1}" err
  if [[ "${2}" == True ]]; then
    showhelp
  elif [[ ${2} =~ ^[[:digit:]]+$ ]]; then
    ret=${2}
  fi
  _sshexit
  exit ${ret}
}

#Func: replace prefix ~ to absolute path
#      $1: path
#    [$2]: optional username,
#          if $2 exists, this function runs under actions,
#          which means should consider ssh connection
#return: absolute path
function _absolutepath() {
  local p="${1}"
  if [[ "${p}" =~ ^~ ]]; then
    local ua=${2:+1}
    local h="${p%%/*}"
    local r="${p:${#h}}"
    local u=${h:1}
    u=${u:-${2}}
    [[ ! "${u}" =~ [[:space:]] ]] || fatalerr "Unsupported username!"
    if [[ ${ua} == 1 ]]; then
      eval "h=\"\$(_echo -n ~${u})\""
    else
      eval "h=\"\$(echo -n ~${u})\""
    fi
    p="${h}${r}"
  fi
  echo -n "${p}"
}

#Func: fatal relative path
#      $1: path
function _fatalunsupportedpath() {
  if [[ ! "${1}" =~ ^/ ]]; then
    fatalerr "Relative path '${1}' detected, please use absolute path!"
  fi
  if [[ "${1}" =~ \\/ ]]; then
    fatalerr "Path should not contains '\/'!"
  fi
}

#Func: return username fron userid
#      $1: userid
#return: username
function _getuname() {
  local u
  eval "u=\$(_getent passwd ${1} | { IFS=':'; read un _; echo -n \${un:-erroruser}; })"
  echo -n "${u}"
}

#Func: check write permission for destination
#      $1: path <STRING>
#      $2: force to add exec permission or not <true|false>
#    [$3]: extra info
function _checkwriteperm() {
  if ! _is_dir "${1}"; then
    printlog "Skip write permission check for non-directory '${1}'" warn
    return
  fi
  if ! _is_writeable "${1}"; then
    printlog "Has no write permission to path '${1}'${3}" warn
    fatalerr "You should run z16 with a proper user! Bye~"
  else
    if ! _is_executable "${1}"; then
      [[ "${2}" != "true" ]] || eval "_chmod a+x '${1}'" #TODO: Minimally invasive
    fi
  fi
}

# vim: et:ts=2:sts:sw=2
