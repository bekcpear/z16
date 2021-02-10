#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: show help informations
#retrun: $?
function showhelp() {
  echo "===help msg==="
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

#Func: check if existed
#      $1: path <STRING>
#      $2: type <file|dir>
#retrun: $?
function checkexi() {
  :
}

#Func: do some check, e.g.: check executed user and the owner/group of symbolic links
#return: $?
function check() {
  :
}

# vim: et:ts=2:sts:sw=2
