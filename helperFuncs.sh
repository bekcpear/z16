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
  --config=<path>, -c   Use this user-level configuration file instead of the default ~/.config/z16/z16rc.
  --force, -f           Force override the destination.
  --pretend, -p         Pretend to load/unload (temporary files will be created anyway)
  --verbose, -v         Show more informations.

commands:
  init   (<instance>)   Initialize instance(s).
  load   (<instance>)   Create symbolic links to files of the instance(s).
  unload (<instance>)   Remove symbolic links belonging to the instance(s).
  list                  List all instances.
  help                  Show this help message.
"
}

#Func: print log
#      $1: msg  <STRING>
#    [$2]: type <stage|warn|err> (default: info)
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
  eval "echo -e \"${color}[$(date +%H:%M:%S) ${type}] ${1//\"/\\\"}\e[0m\" >${out}"
}

#Func: exit shell and print error
#      $1: msg              <STRING>
#    {$2]: show help or not <True|False> (default: False)
#return: $?
function fatalerr() {
  printlog "${1}" err
  if [[ "${2}" == True ]]; then
    showhelp
  fi
  exit 1
}

#Func: replace prefix ~ to absolute path
#      $1: path
#    [$2]: optional username
#return: absolute path
function _absolutepath() {
  local p="${1}"
  if [[ "${p}" =~ ^~ ]]; then
    local h="${p%%/*}"
    local r="${p:${#h}}"
    local u=${h:1}
    u=${u:-${2}}
    [[ ! "${u}" =~ [[:space:]] ]] || fatalerr "Unsupported username!"
    eval "h=\"\$(echo -n ~${u})\""
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
  eval "u=\$(getent passwd ${1} | { IFS=':'; read un _; echo -n \${un:-erroruser}; })"
  echo -n "${u}"
}

#Func: check write permission
#      $1: path <STRING>
#      $2: force to add exec permission or not <true|false>
#    [$3]: extra info
function _checkwriteperm() {
  if [[ ! -d "${1}" ]]; then
    printlog "Skip write permission check for non-directory '${1}'" warn
    return
  fi
  if [[ ! -w "${1}" ]]; then
    printlog "Has no write permission to path '${1}'${3}" warn
    fatalerr "You should run z16 with a proper user! Bye~"
  else
    if [[ ! -x "${1}" ]]; then
      [[ "${2}" != "true" ]] || eval "chmod a+x '${1}'" #TODO: Minimally invasive
    fi
  fi
}

#Func: check path, service for check()
#      $1: path
#      $2: user
#    [$3]: instance index
#return: absolute path
function _checkpath() {
  local p="${1}"
  local u="${2}"

  local info
  if [[ -n "${3}" ]]; then
    info="instance '${INSTANCES[${3}]}'"
  else
    info="global configurations"
  fi

  if [[ "${u}" =~ ^[[:digit:]]+$ ]]; then
    eval "u=\$(_getuname ${u})"
  fi
  eval "p=\$(_absolutepath '${p}' '${u}')"
  _fatalunsupportedpath "${p}"
  if [[ ! -d "${p}" ]]; then
    eval "local -r d_tmpdir=\"\${D_${D_VARS_G[1]}}\""
    if [[ "${p}" == "${d_tmpdir}" ]]; then
      mkdir -p "${p}"
    else
      printlog "Path '${p}' of ${info} does not exist." warn
      fatalerr "Please create it manually!"
    fi
  fi

  _checkwriteperm "${p}" "true" " of ${info}"

  echo -n "${p}"
}

#Func: do some check, e.g.: check executed user and the owner/group of symbolic links
function check() {
  local -i i
  local -a p u g ur gr
  local p_d u_d g_d

  eval "p_d=\"\${CONFIGS[${D_VARS_L[0]}]}\""
  eval "u_d=\"\${CONFIGS[${D_VARS_L[1]}]:=${CUSER}}\""
  eval "g_d=\"\${CONFIGS[${D_VARS_L[2]}]:=${CGROUP}}\""

  for (( i = 0; i < ${#INSTANCES[@]}; ++i )); do
    eval "ur[i]=\"\${CONFIGS_${i}[${D_VARS_L[1]}]}\""
    eval "gr[i]=\"\${CONFIGS_${i}[${D_VARS_L[2]}]}\""

    eval "p[i]=\"\${CONFIGS_${i}[${D_VARS_L[0]}]}\""
    eval "u[i]='${ur[i]:-${u_d}}'"
    eval "g[i]='${gr[i]:-${g_d}}'"
  done

  local -ri ilen=${#p[@]}

  #check path
  for (( i = 0; i < ${ilen}; ++i )); do
    if [[ -z "${p[i]}" ]]; then
      printlog "${D_VARS_L[0]} of instance '${INSTANCES[i]}' is not set, fallback to the global setting." warn
      eval "p[i]=\"\$(_checkpath '${p_d}' '${u[i]}')\""
    else
      eval "p[i]=\$(_checkpath '${p[i]}' '${u[i]}' ${i})"
    fi
  done

  # unify configurations
  # replace username/groupname to uid/gid to avoid unforeseen errors
  local -a ui gi
  for (( i = 0; i < ${ilen}; ++i )); do
    eval "CONFIGS_${i}[${D_VARS_L[0]}]='${p[i]}'"
    if [[ ! "${u[i]}" =~ ^[[:digit:]]+$ ]]; then
      eval "ui[${i}]=\$(getent passwd ${u[i]} | { IFS=':'; read _ _ un _; echo -n \${un:-999999}; })"
    fi
    eval "CONFIGS_${i}[${D_VARS_L[1]}]='${ui[i]:=${u[i]}}'"
    if [[ ! "${g[i]}" =~ ^[[:digit:]]+$ ]]; then
      eval "gi[${i}]=\$(getent group ${g[i]} | { IFS=':'; read _ _ un _; echo -n \${un:-999999}; })"
    fi
    eval "CONFIGS_${i}[${D_VARS_L[2]}]='${gi[i]:=${g[i]}}'"
  done

  #check user and groups
  if [[ "${CUSER}" == 0 ]]; then
    return
  fi
  local -a otherusers othergroups
  for (( i = 0; i < ${ilen}; ++i )); do
    #check user
    if [[ "${CUSER}" != "${ui[i]}" ]]; then
      eval "otherusers[${i}]=${i}"
    fi
    #check groups
    if [[ ! "${gi[i]}" =~ ${CGROUPS} ]]; then
      eval "othergroups[${i}]=${i}"
    fi
  done
  if [[ ${#otherusers[@]} > 0 || ${#othergroups[@]} > 0 ]]; then
    printlog "Ownership cannot be handled!" warn
    if [[ ${#otherusers[@]} > 0 ]]; then
      printlog "  file owner:" warn
      for i in "${otherusers[@]}"; do
        printlog "    '${u[i]}' for instance: '${INSTANCES[i]}'" warn
        if [[ "${ur[i]}" != "${u[i]}" ]]; then
          printlog '      \`-- (which inherited from global settings)' warn
        fi
      done
    fi
    if [[ ${#othergroups[@]} > 0 ]]; then
      printlog "  file group:" warn
      for i in "${othergroups[@]}"; do
        printlog "    '${g[i]}' for instance: '${INSTANCES[i]}'" warn
        if [[ "${gr[i]}" != "${g[i]}" ]]; then
          printlog '      \`-- (which inherited from global settings)' warn
        fi
      done
    fi
    fatalerr "You should run z16 or set the instance with a proper user! Bye~"
  fi
}

# vim: et:ts=2:sts:sw=2
