#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

source "${SPATH%/*}"/main/check.sh
source "${SPATH%/*}"/main/config.sh
source "${SPATH%/*}"/main/fetch.sh
source "${SPATH%/*}"/main/init.sh
source "${SPATH%/*}"/main/list.sh
source "${SPATH%/*}"/main/load.sh
source "${SPATH%/*}"/main/unload.sh

#Func: prepare, clear tmpdir #TODO: more reliable
#      $1 clear or not (BOOL)
function _preptmp() {
  local re=''
  if [[ -d "${Z16_TMPDIR}" ]]; then
    eval "rm -rf '${Z16_TMPDIR}'"
    re='re'
  fi
  if [[ -z ${1} ]]; then
    eval "mkdir -p '${Z16_TMPDIR}'"
    printlog "---> Temporary directory '${Z16_TMPDIR}' ${re}created."
  else
    printlog "<--- Temporary directory '${Z16_TMPDIR}' removed."
  fi
}

#Func: get ignore pattern according to the instance
#      $1: instance index
#return: POSIX extended regex
function _get_igno() {
  local m igno append
  eval "local -a mi=( \"\${IGNORES_${1}[@]}\" )"
  for igno in "${IGNORES[@]}" "${mi[@]}"; do
    append=1
    if [[ "${igno}" =~ ^! ]]; then
      append=0
      igno="${igno#!}"
    fi
    #TODO: more detailed
    igno="${igno#\\\./}"
    igno="${igno/#\?/\\?}"
    igno="${igno/#\+/\\+}"
    igno="${igno/#\*/\\*}"
    igno="${igno/\{/\\\{}"
    if [[ "${append}" == 0 ]]; then
      m="${m//${igno}|}"
    else
      m+="${igno}|"
    fi
  done
  echo -n "^(${m}${CONFIGS[${D_VARS_G[0]}]})$"
}
#Func: get the list array under a path
#      Only run locally!
#      $1 path
#      $2 regex
#return: an array declare string
function _get_list() {
  local -i i=0
  local rpath="${1#${instp}}"
  rpath="${rpath#/}"
  ssraw="local -a ss=($(eval "ls -A1 ${1}" | while read -r source; do
    local r="${rpath%/}/${source}"
    if [[ "${r#/}" =~ ${2} ]]; then
      continue
    fi
    eval "echo -n '[${i}]=\"${source}\" '"
    i+=1
  done))"
  echo -n "${ssraw}"
}

#Func: parse dot- prefix and return
#      $1 item name
function _parse_dot_prefix() {
  if [[ "${1}" =~ ^(d|D)(o|O)(t|T)\- ]]; then
    echo -n ".${1:4}"
  else
    echo -n "${1}"
  fi
}

#Func: load/unload/fetch/config instance
#      $1: action and instance name(s)
#return: $?
function zdo() {
  local -a c
  local -i cc=${#D_VARS_L[@]}
  local -i i=0
  local act=${1}
  shift

  printlog ">> Do ${act/%ig/igur}ing instance${2:+s}..." stage
  if [[ ${act} == load ]]; then
    _preptmp
  fi
  for inst; do
    #get configurations
    local -i j
    for (( j = 0; j < cc; ++j )); do
      eval "c[j]=\${CONFIGS_${i}[${D_VARS_L[j]}]:-${CONFIGS[${D_VARS_L[j]}]}}"
    done

    #do action
    case ${act} in
      load)
        printlog ">>> preloading instance \"${inst}\"..."
        printlog "--- the parent dir has been set to '${c[0]}'"
        printlog "--- the owner has been set to uid: ${c[1]}"
        printlog "--- the group has been set to gid: ${c[2]}"
        #make symbolic links
        mklink "${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}" "$(declare -p c)" ${i}
        printlog "*** instance \"${inst}\" preloaded."
        ;;
      unload)
        printlog ">>> unloading instance \"${inst}\"..."
        rmlink "${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}" "$(declare -p c)" ${i}
        printlog "*** instance \"${inst}\" unloaded."
        ;;
      fetch)
        printlog ">>> fetching instance \"${inst}\"..."
        fetch "${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}" "$(declare -p c)" ${i}
        printlog "*** instance \"${inst}\" fetched."
        ;;
      config)
        printlog ">>> configuring instance \"${inst}\"..."
        config "${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}" "$(declare -p c)" ${i}
        printlog "*** instance \"${inst}\" configured."
        ;;
      *)
        fatalerr "Unknown error!"
        ;;
    esac
    i+=1
  done
  if [[ ${act} == load ]]; then
    printlog "** Instance${2:+s} preloaded." stage
    merge
  fi
  printlog "== Instance${2:+s} ${act/%ig/igur}ed!" stage
  _sshexit
}

#Func: do main function
#return: $?
function execmain() {
  case ${CMD} in
    init)
      init ${INSTANCES[@]}
      ;;
    load)
      check
      [[ ${PRETEND} == 0 ]] || printlog "Enter pretend mode!" warn
      zdo load ${INSTANCES[@]}
      ;;
    unload)
      check
      [[ ${PRETEND} == 0 ]] || printlog "Enter pretend mode!" warn
      zdo unload ${INSTANCES[@]}
      ;;
    fetch)
      check
      [[ ${PRETEND} == 0 ]] || printlog "Enter pretend mode!" warn
      zdo fetch ${INSTANCES[@]}
      ;;
    config)
      check
      zdo config ${INSTANCES[@]}
      ;;
    list)
      list #TODO: with arguments
      ;;
    help)
      showhelp
      exit 0
      ;;
    *)
      fatalerr "Unknown command: ${CMD}"
  esac
}

# vim: et:ts=2:sts:sw=2
