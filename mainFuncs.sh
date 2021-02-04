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

#Func: make symbolic link
#      $1: source <STRING>
#      $2: target <STRING>
#      $3: owner  <USERNAME>    optional, default to env default
#      $4: group  <GROUPNAME>   optional, default to env default
#      $5: perm   <PERM-STRING> optional, default to env default
#retrun: $?
function mklink() {
  :
}

#Func: remove symbolic link
#      $1: target <STRING>
#retrun: $?
function rmlink() {
  :
}

#Func: parse instance configuration, refer LINE 30
#      $1: configfile <STRING> optional, default to INSTANCE-DIR/.z16.l.conf
#retrun: $?
function parseinstconfig() {
  :
}

#Func: init instance
#      $1: instance name(s)
#return: $?
function init() {
  echo init: $@
}

#Func: list instance
#    [$1]: instance name(s)
#return: $?
function list() {
  echo list: $@
}


#Func: load instance
#      $1: instance name(s)
#return: $?
function load() {
  echo load: $@
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
    list)
      list ${INSTANCES[@]}
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
    help)
      showhelp
      exit 0
      ;;
    *)
      fatalerr "Unknown command: ${CMD}"
  esac
}

# vim: et:ts=2:sts:sw=2
