#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: write to file
#      $1: contents <STRING>
#      $2: file     <STRING>
#return: $?
function write() {
  :
}

#Func: prepare, clear tmpdir #TODO: more reliable
#      $1 clear or not (BOOL)
function preptmp() {
  [[ ! -d "${Z16_TMPDIR}" ]] || eval "rm -rf '${Z16_TMPDIR}'"
  if [[ -n ${1} ]]; then
    eval "mkdir -p '${Z16_TMPDIR}'"
  fi
}

#Func: make symbolic link
#      $1: instance dir <STRING>
#      $2: config <ARRAY>
#retrun: $?
function mklink() {
  local -i ret=0
  local p="${1}"
  eval "${2/declare/local}" # configuration array: c
  local ssraw
  local -i i=0
  local -i j

  local ldir="${Z16_TMPDIR%/}/${c[0]%/}"
  [[ -d ${ldir} ]] || mkdir -p "${ldir}"
  ssraw="local -a ss=($(eval "ls -a1 ${p}" | while read -r source; do
    if [[ "${source}" =~ ^\.$|^\.\.$|^${CONFIGS[${D_VARS_G[0]}]}$ ]]; then
      continue
    fi
    eval "echo -n '[${i}]=\"${source}\" '"
    i+=1
  done))"
  eval "${ssraw}"
  for (( j = 0; j < ${#ss[@]}; ++j )); do
    ln -sn "${p%/}/${ss[j]}" "${ldir}/${ss[j]}" || ret+=$?
    chown -R ${c[1]:-${CUSER}}:${c[2]:-${CGROUP}} "${ldir}/${ss[j]}" || ret+=$?
    #change the user & group of the source file
    chown -R ${c[1]:-${CUSER}}:${c[2]:-${CGROUP}} "${p%/}/${ss[j]}" || ret+=$?
  done
  if [[ ${ret} > 0 ]]; then
    fatalerr "something errors when making symbolic links of \"${p##*/}\"!"
  fi
}

#Func: merge links from tmp dir to root fs
function merge() {
  local -i ret=0
  #[[ ${ret} != 0 ]] || preptmp c
}

#Func: remove symbolic link
#      $1: target <STRING>
#retrun: $?
function rmlink() {
  :
}

#Func: init instance
#      $1: instance name(s)
#return: $?
function init() {
  for inst; do
    eval "mkdir -p \"\${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}\""
    eval "touch \"\${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst%/}/\${CONFIGS[${D_VARS_G[0]}]}\""
    #TODO
  done
}

#Func: list instance
#    [$1]: instance name(s) #TODO
#return: $?
function list() {
  local -a lists
  eval "lists=( \$(ls -1 \${CONFIGS[${D_VARS_Z16[0]}]}) )"
  local i
  for (( i = 0; i < ${#lists[@]}; ++i )); do
    echo ${lists[i]}
  done
}


#Func: load instance
#      $1: instance name(s)
#return: $?
function load() {
  local -a c
  local -i cc=${#D_VARS_L[@]}
  local -i i=0
  preptmp
  for inst; do
    printlog ">> preloading instance \"${inst}\"..."
    #get configurations
    local -i j
    for (( j = 0; j < cc; ++j )); do
      eval "c[j]=\${CONFIGS_${i}[${D_VARS_L[j]}]:-${CONFIGS[${D_VARS_L[j]}]}}"
    done
    #make symbolic links
    mklink "${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}" "$(declare -p c)"
    printlog "** instance \"${inst}\" preloaded!"
    i+=1
  done
  merge
}

#Func: unload instance
#      $1: instance name(s)
#return: $?
function unload() {
  :
}

#Func: config instance
#      $1: instance name(s)
#return: $?
function config() {
  :
}

#Func: do main function
#return: $?
function execmain() {
  case ${CMD} in
    init)
      init ${INSTANCES[@]}
      ;;
    load)
      load ${INSTANCES[@]}
      ;;
    unload)
      unload ${INSTANCES[@]}
      ;;
    config)
      config ${INSTANCES[@]}
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
