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
function _preptmp() {
  [[ ! -d "${Z16_TMPDIR}" ]] || eval "rm -rf '${Z16_TMPDIR}'"
  if [[ -z ${1} ]]; then
    eval "mkdir -p '${Z16_TMPDIR}'"
  fi
}

#Func: get the list array under a path
#      $1 path
function _get_list() {
  local ssraw
  local -i i=0
  ssraw="local -a ss=($(eval "ls -A1 ${1}" | while read -r source; do
    if [[ "${source}" =~ ^${CONFIGS[${D_VARS_G[0]}]}$ ]]; then
      continue
    fi
    eval "echo -n '[${i}]=\"${source}\" '"
    i+=1
  done))"
  echo -n "${ssraw}"
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
  local -i j

  PATH_STACK=( "${PATH_STACK[@]}" "${c[0]}" )
  local ldir="${Z16_TMPDIR%/}/${c[0]}"
  [[ -d ${ldir} ]] || mkdir -p "${ldir}"
  eval "ssraw=\"\$(_get_list '${p}')\""
  eval "${ssraw}"

  if [[ ${#ss[@]} == 0 ]]; then
    printlog "Instance '${p##*/}' has no file, continue!" warn
    return
  fi
  for (( j = 0; j < ${#ss[@]}; ++j )); do
    ln -sn "${p%/}/${ss[j]}" "${ldir}/${ss[j]}" || ret+=$?
    chown -R ${c[1]:-${CUSER}}:${c[2]:-${CGROUP}} "${ldir}/${ss[j]}" || ret+=$?
    #change the user & group of the source file
    chown -R ${c[1]:-${CUSER}}:${c[2]:-${CGROUP}} "${p%/}/${ss[j]}" || ret+=$?
  done
  if [[ ${ret} > 0 ]]; then
    fatalerr "something errors when making symbolic links of '${p##*/}'!"
  fi
}

#Func: merge links from tmp dir to root fs
function merge() {
  printlog ">> Merging to filesystem..." stage
  eval "pushd '${Z16_TMPDIR}' 1>/dev/null 2>${VERBOSEOUT2}"
  local -i i
  for (( i = 0; i < ${#PATH_STACK[@]}; ++i )); do
    local path="${PATH_STACK[i]}"
    if [[ ! -d "${path}" ]]; then
      eval "mkdir -p \"${path}\""
      printlog "Path '${path}' does not exist! Created by current user." warn
    fi
    eval "ls -A1 \"${path#/}\"" | \
    while IFS= read -r item; do
      eval "lparent=\$(readlink -fn '${path#/}/${item}')"
      lparent="${lparent%/*}"
      if [[ ! -e "${path}/${item}" ]] || \
         [[ \
            -L "${path}/${item}" && \
            $(readlink -fn "${path}/${item}") =~ ^${lparent} \
         ]]; then
        eval "cp -af \"${path#/}/${item}\" \"${path}\""
      else
        printlog "Skip existing: '${path%/}/${item}'" warn
      fi
    done
  done
  eval "popd 1>/dev/null 2>${VERBOSEOUT2}"
  printlog "** Merged!" stage
  #_preptmp clean
}

#Func: remove symbolic link
#      $1: instance dir <STRING>
#      $2: config <ARRAY>
function rmlink() {
  local -i ret=0
  local -i i
  eval "${2/declare/local}" # configuration array: c
  local p="${1}"
  local ssraw
  eval "ssraw=\"\$(_get_list '${p}')\""
  eval "${ssraw}"

  local -a links
  for (( i = 0; i < ${#ss[@]}; ++i )); do
    if [[ -L "${c[0]}/${ss[i]}" ]]; then
      links=( "${links[@]}" "${c[0]}/${ss[i]}" )
    fi
  done

  if [[ ${#links[@]} > 0 ]]; then
    for (( i = 0; i < ${#links[@]}; ++i )); do
      unlink "${links[i]}"
    done
  else
    printlog "Instance '${p##*/}' already unloaded!" warn
  fi
}

#Func: init instance
#      $1: instance name(s)
#return: $?
function init() {
  for inst; do
    local cpath
    eval "cpath=\"\${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst%/}/\${CONFIGS[${D_VARS_G[0]}]}\""
    eval "mkdir -p \"\${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}\""
    if [[ ! -e "${cpath}" ]]; then
      eval "touch \"\${cpath}\""
      eval "INIT_VARS[${D_VARS_L[0]}_C]='The parent folder path of the instance'"
      eval "INIT_VARS[${D_VARS_L[0]}]=\${D_${D_VARS_L[0]}}"
      eval "INIT_VARS[${D_VARS_L[1]}_C]='The owner of the symbolic links'"
      eval "INIT_VARS[${D_VARS_L[1]}]=\${D_${D_VARS_L[1]}}"
      eval "INIT_VARS[${D_VARS_L[2]}_C]='The group of the symbolic links'"
      eval "INIT_VARS[${D_VARS_L[2]}]=\${D_${D_VARS_L[2]}}"
      _init_writevar D_VARS_L ${#D_VARS_L[@]} "${cpath}" "This is the local configuration file of instance." mask
    fi
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


#Func: load/unload instance
#      $1: action and instance name(s)
#return: $?
function load() {
  local -a c
  local -i cc=${#D_VARS_L[@]}
  local -i i=0
  local act=${1}
  shift

  printlog ">> Do ${act}ing instance$([[ $# == 1 ]] || echo -n s)..." stage
  if [[ ${act} == load ]]; then
    _preptmp
  fi
  for inst; do
    #get configurations
    local -i j
    for (( j = 0; j < cc; ++j )); do
      eval "c[j]=\${CONFIGS_${i}[${D_VARS_L[j]}]:-${CONFIGS[${D_VARS_L[j]}]}}"
    done
    if [[ "${c[0]}" =~ ^~ ]]; then
      local homedir
      eval "homedir=\$(echo -n ~${c[1]:-${CUSER}})"
      c[0]=${c[0]/\~/${homedir}}
    fi
    if [[ ! "${c[0]}" =~ ^/ ]]; then
      fatalerr "Relative path '${c[0]}' detected, please use absolute path!"
    fi
    c[0]="${c[0]%/}"

    #do action
    if [[ ${act} == load ]]; then
      printlog ">>> preloading instance \"${inst}\"..."
      #make symbolic links
      mklink "${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}" "$(declare -p c)"
      printlog "*** instance \"${inst}\" preloaded."
    else
      printlog ">>> unloading instance \"${inst}\"..."
      rmlink "${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}" "$(declare -p c)"
      printlog "*** instance \"${inst}\" unloaded."
    fi
    i+=1
  done
  if [[ ${act} == load ]]; then
    merge
  fi
  printlog "== Instance$([[ $# == 1 ]] || echo -n s) ${act}ed!" stage
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
      load load ${INSTANCES[@]}
      ;;
    unload)
      load unload ${INSTANCES[@]}
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
