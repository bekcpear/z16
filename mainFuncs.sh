#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: write to file #TODO
#      $1: contents <STRING>
#      $2: file     <STRING>
#return: $?
function write() {
  :
}

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

#Func: loop max 100 times to create directory **with ownership**
#      $1: path
#    [$2]: ownership, ommited for merging funcion
function _looptomkdir() {
  local -i j k=1
  local -a pathstack
  local p="${1%/}"
  pathstack[0]="${p}"
  for (( j = 0; j < 100; ++j )); do
    p="${p%/*}"
    if [[ ! -e "${p}" ]]; then
      eval "pathstack[${k}]='${p}'"
      k+=1
    else
      break
    fi
    if [[ "${j}" == 99 ]]; then
      fatalerr "Too many loops when creating directroy!"
    fi
  done
  for (( j = ${#pathstack[@]} - 1; j >= 0; --j )); do
    p="${pathstack[j]}"

    if [[ -z ${2} ]]; then
        #This condition only works for merging function, BELOW
        _checkwriteperm "${p%/*}/" "false"
        printlog "--> creating directory '${p}'"
        local oownership="$( ls -nd ".${p}" | { IFS=$' \t' read -r _ _ u g _; echo "${u}:${g}"; } )"
        [[ "${oownership}" =~ ^[[:digit:]]+:[[:digit:]]+$ ]] || \
          fatalerr "Merging error! (unrecognized ownership got)"
        #This condition only works for merging function, ABOVE
    else

      local oownership="${2}"
    fi
    if [[ ${PRETEND} == 0 || -n ${2} ]]; then
      mkdir -Z "${p}" || ret+=$?
      eval "chown '${oownership}' '${p}'" || ret+=$?
    fi
  done
}

#Func: meta function to make symbolic links
#      $1: located directory
#      $2: path (file or directory)
#      $3: instance index
function _mklink() {
  local p="${2}"
  if [[ -d "${p}" ]]; then
    local -i i
    local ssraw
    eval "ssraw=\"\$(_get_list '${p}' '${instm}')\""
    eval "${ssraw}"
    if [[ ${#ss[@]} == 0 ]]; then
      return
    fi
    for (( i = 0; i < ${#ss[@]}; ++i )); do
      local rpath
      eval "rpath=\$(_parse_dot_prefix '${p##*/}')"
      _mklink "${1%/}/${rpath}" "${p}/${ss[i]}" "${3}"
    done
  else
    local -i ret
    if [[ ! -e "${1}" ]]; then
      _looptomkdir "${1}" "${c[1]}:${c[2]}"
    fi
    if [[ ! -d "${1}" ]]; then
      fatalerr "Z16 error: '${1}' is not a directory!"
    fi

    local ldest
    eval "ldest=\"${1%/}/\$(_parse_dot_prefix '${p##*/}')\""
    printlog "---> link '${ldest/#${Z16_TMPDIR%/}/[TMP]}' to '${p}'"
    ln -sn "${p}" "${ldest}" || ret+=$?
    eval "chown -h ${c[1]}:${c[2]} '${ldest}'" || ret+=$?
    if [[ ${ret} > 0 ]]; then
      fatalerr "Error in making symbolic links of instance '${INSTANCES[${3}]}'!"
    fi
  fi
}
#Func: make symbolic link
#      $1: instance dir <STRING>
#      $2: config <ARRAY>
#      $3: instance index
function mklink() {
  local instm instp="${1}"
  eval "${2/declare/local}" # configuration array: c
  eval "instm=\"\$(_get_igno ${3})\""
  #sub '_mklink' & '_get_list' function inherit c & instp & instm

  local ssraw
  eval "ssraw=\"\$(_get_list '${instp}' '${instm}')\""
  eval "${ssraw}"
  if [[ ${#ss[@]} == 0 ]]; then
    printlog "Instance '${INSTANCES[${3}]}' has no file, continue!" warn
    return
  fi

  local -i i ret=0
  local ldir="${Z16_TMPDIR%/}/${c[0]#/}"
  for (( i = 0; i < ${#ss[@]}; ++i )); do
    _mklink "${ldir%/}" "${instp%/}/${ss[i]}" "${3}"
    #change the user & group of the source files
    chown -R ${c[1]}:${c[2]} "${instp%/}/${ss[i]}" || ret+=$?
    if [[ ${ret} > 0 ]]; then
      fatalerr "Error in changing the ownership of instance '${INSTANCES[${3}]}'!"
    fi
  done
}

#Func: meta function for merging files TODO: harden it
#      $1: located path
#      $2: source file
function _merge() {
  if [[ -z $2 ]]; then
    printlog "No more sources, continue" warn
    return
  fi

  local -i ret=0
  local rsrc="${1}/${2}"

  if [[ -d "${rsrc}" ]]; then
    while read -r source; do
      _merge "${rsrc}" "${source}" || fatalerr "Merging error! (sub)"
    done <<< $(ls -A1 "${rsrc}")
  else
    if [[ ! -L "${rsrc}" ]]; then
      printlog "Skipping non-linked file '${rsrc}'" warn
      return
    fi
    local crp="${1#.}" # corresponding root path
    if [[ ! -e "${crp}" ]]; then
      _looptomkdir "${crp}"
    else
      _checkwriteperm "${crp}" "false"
    fi
    [[ ${ret} == 0 ]] || return ${ret}

    #do merging links
    if [[ ${FORCEOVERRIDE} == 1 ]] || \
       [[ ! -e "${rsrc#.}" && ! -L "${rsrc#.}" ]]; then
      printlog "--> merging to '${rsrc#.}'"
      if [[ ${PRETEND} == 0 ]]; then
        eval "cp -af '${rsrc}' '${crp%/}/'" || ret+=$?
      fi
    else
      printlog "Skip existing: '${rsrc#.}'" warn
    fi
  fi
  return ${ret}
}
#Func: merge links from tmp dir to root fs
function merge() {
  printlog ">> Merging to filesystem..." stage
  eval "pushd '${Z16_TMPDIR}' 1>/dev/null 2>${VERBOSEOUT2}"
  while read -r source; do
    _merge "." "${source}" || fatalerr "Merging error!"
  done <<< $(ls -A1 .)
  eval "popd 1>/dev/null 2>${VERBOSEOUT2}"
  printlog "** Merged!" stage
  if [[ ${PRETEND} == 0 ]]; then
    _preptmp clean
  fi
}

#Func: remove empty directory
#      $1: path
function _rmemptydir() {
  [[ -d "${1}" ]] || return 0
  local c=$(ls -A1 "${1}")
  if [[ -z ${c} ]]; then
    printlog "<--- Removing empty directory '${1}'" warn
    if [[ ${PRETEND} == 0 ]]; then
      rmdir "${1}" || fatalerr "Remove empty directory error!"
    fi
  fi
}
#Func: meta function to unlink
#      $1: corresponding root path
#      $2: path (file or directory)
#      $3: instance index
function _rmlink() {
  if [[ -d "${2}" ]]; then
    local -i i
    local ssraw
    eval "ssraw=\"\$(_get_list '${2}' '${instm}')\""
    eval "${ssraw}"
    if [[ ${#ss[@]} == 0 ]]; then
      _rmemptydir "${1}"
      return
    fi
    for (( i = 0; i < ${#ss[@]}; ++i )); do
      local rpath
      eval "rpath=\$(_parse_dot_prefix '${ss[i]}')"
      _rmlink "${1%/}/${rpath}" "${2%/}/${ss[i]}" "${3}"
    done
    _rmemptydir "${1}"
  else
    if [[ -L "${1}" ]]; then
      if [[ $(readlink "${1}") =~ ^${instp} ]]; then
        printlog "<--- unlinking '${1}'"
        if [[ ${PRETEND} == 0 ]]; then
          unlink "${1}" || fatalerr "Unload error!"
        fi
      else
        printlog "The target of '${1}' is not belong to instance '${INSTANCES[${3}]}', skipping!" warn
      fi
    else
      [[ -e "${1}" ]] || return 0
      printlog "Skipping non-linked file '${1}', it's weird!" warn
    fi
  fi
}
#Func: remove symbolic link
#      $1: instance dir <STRING>
#      $2: config <ARRAY>
#      $3: instance index
function rmlink() {
  local instm instp="${1%/}"
  eval "${2/declare/local}" # configuration array: c
  eval "instm=\"\$(_get_igno ${3})\""
  #sub '_rmlink' & '_get_list' function inherit c & instp & instm

  local ssraw
  eval "ssraw=\"\$(_get_list '${instp}' '${instm}')\""
  eval "${ssraw}"

  for (( i = 0; i < ${#ss[@]}; ++i )); do
    local rpath
    eval "rpath=\$(_parse_dot_prefix '${ss[i]}')"
    _rmlink "${c[0]%/}/${rpath}" "${instp}/${ss[i]}" "${3}"
  done
}

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

#Func: list instance
#    [$1]: instance name(s) #TODO: more details and show configurations
#return: $?
function list() {
  local -a lists
  eval "lists=( \$(ls -1 \${CONFIGS[${D_VARS_Z16[0]}]}) )"
  local i
  for (( i = 0; i < ${#lists[@]}; ++i )); do
    [[ -d "${CONFIGS[${D_VARS_Z16[0]}]%/}/${lists[i]}" ]] || continue
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

    #do action
    if [[ ${act} == load ]]; then
      printlog ">>> preloading instance \"${inst}\"..."
      printlog "--- the parent dir has been set to '${c[0]}'"
      printlog "--- the owner has been set to uid: ${c[1]}"
      printlog "--- the group has been set to gid: ${c[2]}"
      #make symbolic links
      mklink "${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}" "$(declare -p c)" ${i}
      printlog "*** instance \"${inst}\" preloaded."
    else
      printlog ">>> unloading instance \"${inst}\"..."
      rmlink "${CONFIGS[${D_VARS_Z16[0]}]%/}/${inst}" "$(declare -p c)" ${i}
      printlog "*** instance \"${inst}\" unloaded."
    fi
    i+=1
  done
  if [[ ${act} == load ]]; then
    printlog "** Instance$([[ $# == 1 ]] || echo -n s) preloaded." stage
    merge
  fi
  printlog "== Instance$([[ $# == 1 ]] || echo -n s) ${act}ed!" stage
}

#Func: config instance #TODO
#      $1: instance name(s)
#return: $?
function config() {
  printlog "Now only show configurations!" warn
  declare -p CONFIGS
  declare -p IGNORES
  local -i i
  for (( i = 0; i < ${#INSTANCES[@]}; ++i )); do
    eval "declare -p CONFIGS_${i}"
    eval "declare -p IGNORES_${i}"
  done
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
      load load ${INSTANCES[@]}
      ;;
    unload)
      check
      [[ ${PRETEND} == 0 ]] || printlog "Enter pretend mode!" warn
      load unload ${INSTANCES[@]}
      ;;
    config)
      check
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
