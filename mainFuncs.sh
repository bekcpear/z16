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

#Func: parse dot- prefix and return
#      $1 item name
function _parse_dot_prefix() {
  if [[ "${1}" =~ ^(d|D)(o|O)(t|T)\- ]]; then
    echo -n ".${1:4}"
  else
    echo -n "${1}"
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
  local -i i

  PATH_STACK=( "${PATH_STACK[@]}" "${c[0]}" )
  local ldir="${Z16_TMPDIR%/}/${c[0]}"
  [[ -d ${ldir} ]] || mkdir -p "${ldir}"
  eval "ssraw=\"\$(_get_list '${p}')\""
  eval "${ssraw}"

  if [[ ${#ss[@]} == 0 ]]; then
    printlog "Instance '${p##*/}' has no file, continue!" warn
    return
  fi
  for (( i = 0; i < ${#ss[@]}; ++i )); do
    local ldest
    eval "ldest=\"${ldir}/\$(_parse_dot_prefix '${ss[i]}')\""
    ln -sn "${p%/}/${ss[i]}" "${ldest}" || ret+=$?
    chown -R ${c[1]}:${c[2]} "${ldest}" || ret+=$?
    #change the user & group of the source file
    chown -R ${c[1]}:${c[2]} "${p%/}/${ss[i]}" || ret+=$?
  done
  if [[ ${ret} > 0 ]]; then
    fatalerr "Error in making symbolic links of instance '${p##*/}'!"
  fi
}

#Func: merge links from tmp dir to root fs
function merge() {
  printlog ">> Merging to filesystem..." stage
  eval "pushd '${Z16_TMPDIR}' 1>/dev/null 2>${VERBOSEOUT2}"
  local -i i
  for (( i = 0; i < ${#PATH_STACK[@]}; ++i )); do
    local path="${PATH_STACK[i]}"
    eval "ls -A1 \"${path#/}\"" | \
    while IFS= read -r item; do
      eval "lparent=\$(readlink -fn '${path#/}/${item}')"
      lparent="${lparent%/*}"
      if [[ ${FORCEOVERRIDE} == 1 ]] || \
         [[ ! -e "${path}/${item}" ]] || \
         [[ \
            -L "${path}/${item}" && \
            $(readlink -fn "${path}/${item}") =~ ^${lparent} \
         ]]; then
        [[ ! -d "${path}/${item}" ]] || \
          rm -rf "${path}/${item}" && \
          eval "cp -af \"${path#/}/${item}\" \"${path}/\"" || \
          fatalerr "Merge error!"
      else
        printlog "Skip existing: '${path%/}/${item}'" warn
      fi
    done
  done
  eval "popd 1>/dev/null 2>${VERBOSEOUT2}"
  printlog "** Merged!" stage
  _preptmp clean
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
    local dest
    eval "dest=\"${c[0]}/\$(_parse_dot_prefix '${ss[i]}')\""
    if [[ -L "${dest}" ]]; then
      links=( "${links[@]}" "${dest}" )
    fi
  done

  if [[ ${#links[@]} > 0 ]]; then
    for (( i = 0; i < ${#links[@]}; ++i )); do
      eval "unlink '${links[i]}'"
    done
  else
    printlog "Instance '${p##*/}' already unloaded!" warn
  fi
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
    printlog "** Instance$([[ $# == 1 ]] || echo -n s) preloaded." stage
    merge
  fi
  printlog "== Instance$([[ $# == 1 ]] || echo -n s) ${act}ed!" stage
}

#Func: config instance #TODO
#      $1: instance name(s)
#return: $?
function config() {
  printlog "Nothing here!" warn
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
      load load ${INSTANCES[@]}
      ;;
    unload)
      check
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
