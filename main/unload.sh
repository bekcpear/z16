#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: remove empty directory
#      $1: path
function _rmemptydir() {
  _is_dir "${1}" || return 0
  local c=$(_ls -A1 "${1}")
  if [[ -z ${c} ]]; then
    printlog "<--- Removing empty directory '${1}'" warn
    _rmdir "${1}" || fatalerr "Remove empty directory error!"
  fi
}

#Func: unlink/remove links/files of the instance
#      $1: file root path
#      $2: instance index
#      $3: instance dir path
function _remove() {
  if [[ -z ${Z16_SSH[HOSTNAME]} ]]; then
    if [[ -L "${1}" ]]; then
      if [[ $(readlink "${1}") =~ ^${3} ]]; then
        printlog "<--- unlinking '${1}'"
        _unlink "${1}" || fatalerr "Unload error!"
      else
        printlog "The target of '${1}' is not belong to instance '${INSTANCES[${2}]}', skipping!" warn
      fi
    else
      [[ -e "${1}" ]] || return 0
      printlog "Skipping non-linked file '${1}', it's weird!" warn
    fi
  else
    _rm -f "${1}" || fatalerr "Remove '${1}' from remote server via SSH error!"
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
    _remove "${1}" "${3}" "${instp}"
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

  local -i i
  for (( i = 0; i < ${#ss[@]}; ++i )); do
    local rpath
    eval "rpath=\$(_parse_dot_prefix '${ss[i]}')"
    _rmlink "${c[0]%/}/${rpath}" "${instp}/${ss[i]}" "${3}"
  done
}

# vim: et:ts=2:sts:sw=2
