#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: set/get the ownership of tmp file
#      $1: action (get/set)
#      $2: path
#      $3: ownership if set, empty for get
#    $4..: opts
function _tmpownership() {
  local -i ret=0
  local act=${1}
  local file="${2}"
  local ownership="${3}"
  shift;shift;shift
  case ${act} in
    set)
      if [[ -z ${Z16_SSH[HOSTNAME]} ]]; then
        chown "${@}" "${ownership}" "${file}" || ret=$?
        return ${ret}
      else
        echo -n "${ownership}" > "${file}${Z16_OWSP_P}" || ret=$?
        return ${ret}
      fi
      ;;
    get)
      if [[ -z ${Z16_SSH[HOSTNAME]} ]]; then
        ownership="$( ls -nd "${file}" | { IFS=$' \t' read -r _ _ u g _; echo "${u}:${g}"; } )" || ret=$?
      else
        ownership=$(grep ':' "${file}${Z16_OWSP_P}") || ret=$?
      fi
      [[ "${ownership}" =~ ^[[:digit:]]+:[[:digit:]]+$ ]] || \
        fatalerr "Merging error! (unrecognized ownership got)"
      echo -n "${ownership}" || ret+=$?
      return ${ret}
      ;;
    *)
      fatalerr "Unknown error!"
      ;;
  esac
}

#Func: change owner of the files
#      $1: s for source, t for tmp
#      $2: ownership
#      $3: destination file
#      $@: other options
function _chowner() {
  local sot="${1}"
  shift
  local ownership="${1}"
  shift
  local file="${1}"
  shift
  local -i ret=0
  case "${sot}" in
    s)
      if [[ -z ${Z16_SSH[HOSTNAME]} ]]; then
        chown "${@}" "${ownership}" "${file}" || ret=$?
        return ${ret}
      fi
      ;;
    t)
      _tmpownership set "${file}" "${ownership}" "${@}"
      ;;
    *)
      fatalerr "Unknown error!"
      ;;
  esac
  return 0
}

#Func: copy file from source to destination
#      $1: source
#      $2: dest
function _copy() {
  local -i ret=0
  local src="${1}"
  local dest="${2}"
  if [[ -z ${Z16_SSH[HOSTNAME]} ]]; then
    eval "cp -af '${src}' '${dest}'" || ret+=$?
  else
    local rsrc oownership
    rsrc=$(readlink "${src}")
    if [[ ! -e "${rsrc}" && ! -L "${rsrc}" ]]; then
      fatalerr "Source file not exists!"
    fi

    oownership=$(_tmpownership get "${src}" '')
    printlog "transfer to '${Z16_SSH[USER]}@${Z16_SSH[HOSTNAME]}:${dest}${src##*/}':" stage
    if [[ ${PRETEND} == 1 ]]; then
      echo "[Pretend ${Z16_SSH[HOSTNAME]:+(SSH)}] scp \
'${rsrc}' '${Z16_SSH[USER]}@${Z16_SSH[HOSTNAME]}:${dest}${src##*/}'" >&2
    else
      eval "scp $(_sshexec MUX_OPT) -p -P ${Z16_SSH[PORT]} \
        ${Z16_SSH[IDENTITYOPTS]} '${rsrc}' '${Z16_SSH[USER]}@${Z16_SSH[HOSTNAME]}:${dest}${src##*/}'" || ret+=$?
    fi
    _chown -h ${oownership} "${dest}${src##*/}" || ret+=$?
  fi
  return ${ret}
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
    if [[ -n "${2}" && ! -e "${p}" ]] || \
      { [[ -z "${2}" ]] && ! _is_existed "${p}"; }; then
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

    local -i ret=0
    local oownership
    if [[ -z ${2} ]]; then
      # for merging function
      _checkwriteperm "${p%/*}/" "false"
      printlog "--> creating directory '${p}'"
      oownership=$(_tmpownership get ".${p}" '')
      _mkdir -Z "${p}" || ret+=$?
      _chown -h ${oownership} "${p}" || ret+=$?
    else
      # for mklink function
      oownership="${2}"
      mkdir -Z "${p}" || ret+=$?
      _chowner t "${oownership}" "${p}" -h || ret+=$?
    fi

    if [[ ${ret} -ne 0 ]]; then
      fatalerr "Loop to make directories error!" $?
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

  local rsrc="${1}/${2}"

  if [[ -d "${rsrc}" ]]; then
    local -a pr ps
    while read -r source; do
      pr=("${pr[@]}" "${rsrc}")
      ps=("${ps[@]}" "${source}")
    done <<< $(ls -A1 "${rsrc}")
    local -i i
    for (( i = 0; i < ${#pr[@]}; ++i )); do
      _merge "${pr[i]}" "${ps[i]}" || fatalerr "Merging error! (sub)"
    done
  else
    if [[ ! -L "${rsrc}" ]]; then
      if [[ ! ${rsrc} =~ ${Z16_OWSP_P}$ ]]; then
        printlog "Skipping non-linked file '${rsrc}'" warn
      fi
      return
    fi
    local crp="${1#.}" # corresponding root path
    if ! _is_existed "${crp}"; then
      _looptomkdir "${crp}"
    else
      _checkwriteperm "${crp}" "false"
    fi

    #do merging links
    if [[ ${FORCEOVERRIDE} == 1 ]] || \
       ! _is_existed "${rsrc#.}"; then
      printlog "--> merging to '${rsrc#.}'"
      eval "_copy '${rsrc}' '${crp%/}/'" || \
        fatalerr "Merging Error!" $?
    else
      printlog "Skip existing: '${rsrc#.}'" warn
    fi
  fi
}
#Func: merge links from tmp dir to root fs
function merge() {
  printlog ">> Merging to filesystem..." stage
  eval "pushd '${Z16_TMPDIR}' 1>/dev/null 2>${VERBOSEOUT2}"
  local -a psf
  while read -r source; do
    psf=("${psf[@]}" "${source}")
  done <<< $(ls -A1 .)
  local -i i
  for (( i = 0; i < ${#psf[@]}; ++i)); do
    _merge "." "${psf[i]}" || fatalerr "Merging error!"
  done
  eval "popd 1>/dev/null 2>${VERBOSEOUT2}"
  printlog "** Merged!" stage
  : #_preptmp clean
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
    _chowner t "${c[1]}:${c[2]}" "${ldest}" -h || ret+=$?
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

  local ldir="${Z16_TMPDIR%/}/${c[0]#/}"
  for (( i = 0; i < ${#ss[@]}; ++i )); do
    _mklink "${ldir%/}" "${instp%/}/${ss[i]}" "${3}"
    #change the user & group of the source files
    _chowner s "${c[1]}:${c[2]}" "${instp%/}/${ss[i]}" -R || \
      fatalerr "Error in changing the ownership of instance '${INSTANCES[${3}]}'!" $?
  done
}

# vim: et:ts=2:sts:sw=2
