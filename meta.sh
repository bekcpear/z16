#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#
# Execute all commands under the right system.

#Func: execute command remotely through ssh
#      $1: command (MUX_EXIT for exting mux ssh connection,
#                   MUX_OPT for getting mux arguments)
#    $2..: more arguments
function _sshexec() {
  local persistConn="-o 'ControlMaster auto' \
                     -o 'ControlPath /tmp/z16_ssh_socket_%r@%h-%p' \
                     -o 'ControlPersist ${Z16_SSH[MUX_TIMEOUT]}'"
  local url="ssh://${Z16_SSH[USER]}@${Z16_SSH[HOSTNAME]}:${Z16_SSH[PORT]}"
  case "${1}" in
    MUX_EXIT)
      eval "ssh ${persistConn} ${Z16_SSH[IDENTITYOPTS]} -O exit ${url} \
        1>${VERBOSEOUT1} 2>${VERBOSEOUT2}"
      return
      ;;
    MUX_OPT)
      echo -n "${persistConn}"
      return
      ;;
  esac

  local cmd='bash -c '\'
  local cmdparsed=0
  for arg in "${@}"; do
    arg=${arg//\"/\\\"}
    arg=${arg//\'/\'\\\'\'}
    if [[ "${arg}" =~ [[:space:]] && ${cmdparsed} != 0 ]]; then
      cmd+=" \\\"${arg//\"/\\\\\"}\\\""
    else
      cmd+=" ${arg}"
      cmdparsed=1
    fi
  done
  cmd+=\'
  eval "ssh ${persistConn} ${Z16_SSH[IDENTITYOPTS]} ${url} \"${cmd}\"" || exit $?
  #echo "ssh ${persistConn} ${Z16_SSH[IDENTITYOPTS]} ${url} \"${cmd}\"" >&2
}

#
# Command meta functions
function _meta() {
  local pretendcmd="chown|chmod|mkdir|rmdir|unlink|rm"
  local cmd=${1#_}
  shift
  if [[ ${cmd} =~ ^(${pretendcmd})$ && ${PRETEND} == 1 ]]; then
    echo "[Pretend ${Z16_SSH[HOSTNAME]:+(SSH)}] ${cmd}" "${@}" >&2
    return
  fi
  if [[ -z ${Z16_SSH[HOSTNAME]} ]]; then
    eval "${cmd} \"\${@}\""
  else
    _sshexec ${cmd} "${@}"
  fi
}

function _chown() {
  _meta ${FUNCNAME[0]} "$@"
}

function _chmod() {
  _meta ${FUNCNAME[0]} "$@"
}

#Func: fetch files from remote
function _fetch() {
  :
}

function _echo() {
  _meta ${FUNCNAME[0]} "$@"
}

function _id() {
  _meta ${FUNCNAME[0]} "$@"
}

function _ls() {
  _meta ${FUNCNAME[0]} "$@"
}

function _mkdir() {
  _meta ${FUNCNAME[0]} "$@"
}

function _rm() {
  if [[ -z "${Z16_SSH[HOSTNAME]}" ]]; then
    return
  fi
  _meta ${FUNCNAME[0]} "$@"
}

function _rmdir() {
  _meta ${FUNCNAME[0]} "$@"
}

function _unlink() {
  if [[ -n "${Z16_SSH[HOSTNAME]}" ]]; then
    return
  fi
  _meta ${FUNCNAME[0]} "$@"
}

function _getent() {
  _meta ${FUNCNAME[0]} "$@"
}

#
# Check meta functions
function _meta_is() {
  local -i ret=0
  if [[ -n ${Z16_SSH_RAW} ]]; then
    eval "ret=\$(_sshexec 'test -${1} \"${2}\" || echo -n 1')"
  else
    eval "ret=\$(test -${1} \"${2}\" || echo -n 1)"
  fi
  echo -n ${ret}
}
function _is_dir() {
  return $(_meta_is d "${1}")
}

function _is_executable() {
  return $(_meta_is x "${1}")
}

function _is_existed() {
  local -i ret=0
  ret=$(_meta_is e "${1}")
  if [[ ret -eq 0 ]]; then
    return 0
  else
    ret=$(_meta_is L "${1}")
    return ${ret}
  fi
}

function _is_writeable() {
  return $(_meta_is w "${1}")
}

#
# Others
function _showsshinfo() {
  if [[ -n ${Z16_SSH_RAW} ]]; then
    _sshexec echo 'SSH: $(uname -a)'
  fi
}

function _sshexit() {
  if [[ ${Z16_SSH[KEEP]} == 0 && -n ${Z16_SSH_RAW} ]]; then
    _sshexec MUX_EXIT
  fi
}

# vim: et:ts=2:sts:sw=2
