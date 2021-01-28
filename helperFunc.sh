#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: show help informations
#retrun: $?
function showhelp() {
  :
}

#Func: print log
#      $1: msg  <STRING>
#    [$2]: type <warn|err> (default: info)
#retrun: $?
function printlog() {
  :
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

# vim: et:ts=2:sts:sw=2
