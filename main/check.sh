#!/usr/bin/env bash
#
# author: @bekcpear
# license: GPLv2
#

#Func: check the parent path of the instance
#      $1: path
#      $2: user
#    [$3]: instance index
#return: absolute path
function _checkparentpath() {
  local p="${1}"
  local u="${2}"

  local info
  if [[ -n "${3}" ]]; then
    info="instance '${INSTANCES[${3}]}'"
  else
    info="global configurations"
  fi

  if [[ "${u}" =~ ^[[:digit:]]+$ ]]; then
    eval "u=\$(_getuname ${u})"
  fi
  eval "p=\$(_absolutepath '${p}' '${u}')"
  _fatalunsupportedpath "${p}"
  if ! _is_dir "${p}"; then
    eval "local -r d_tmpdir=\"\${D_${D_VARS_G[1]}}\""
    if [[ "${p}" == "${d_tmpdir}" ]]; then
      _mkdir -p "${p}"
    else
      printlog "Path '${p}' of ${info} does not exist." warn
      if [[ ${CMD} != config ]]; then #TODO
        fatalerr "Please create it manually!"
      fi
    fi
  fi

  _checkwriteperm "${p}" "true" " of ${info}"

  echo -n "${p}"
}

#Func: do some check, e.g.: check executed user and the owner/group of symbolic links
function check() {
  # show SSH configurations
  if [[ -n ${Z16_SSH_RAW} ]]; then
    printlog "== SSH connection configurations here!" info
    printlog "                   user: ${Z16_SSH[USER]}" conf
    printlog "               hostname: ${Z16_SSH[HOSTNAME]}" conf
    printlog "                   port: ${Z16_SSH[PORT]}" conf
    printlog "          identity opts: ${Z16_SSH[IDENTITYOPTS]}" conf
    if [[ ${Z16_SSH[KEEP]} == 1 ]]; then
      printlog "             keep alive: True" conf
      printlog "     keep alive timeout: ${Z16_SSH[MUX_TIMEOUT]}" conf
    else
      printlog "             keep alive: False" conf
    fi
  fi

  #current effective user and groups that executing actual commands
  CUSER=$(_id -u)
  CGROUP=$(_id -g)
  CGROUPS_A=( $(_id -G) )
  CGROUPS=
  for CGROUPTMP in "${CGROUPS_A[@]}"; do
    CGROUPS="${CGROUPS}|^${CGROUPTMP}\$"
  done
  CGROUPS="${CGROUPS#|}"
  unset CGROUPS_A CGROUPTMP

  #
  # unify configurations
  local -i i
  local -a p u g ur gr
  local p_d u_d g_d

  eval "p_d=\"\${CONFIGS[${D_VARS_L[0]}]}\""
  eval "u_d=\"\${CONFIGS[${D_VARS_L[1]}]:=${CUSER}}\""
  eval "g_d=\"\${CONFIGS[${D_VARS_L[2]}]:=${CGROUP}}\""

  for (( i = 0; i < ${#INSTANCES[@]}; ++i )); do
    eval "ur[i]=\"\${CONFIGS_${i}[${D_VARS_L[1]}]}\""
    eval "gr[i]=\"\${CONFIGS_${i}[${D_VARS_L[2]}]}\""

    eval "p[i]=\"\${CONFIGS_${i}[${D_VARS_L[0]}]}\""
    eval "u[i]='${ur[i]:-${u_d}}'"
    eval "g[i]='${gr[i]:-${g_d}}'"
  done

  local -ri ilen=${#p[@]}

  #check parent path
  for (( i = 0; i < ${ilen}; ++i )); do
    if [[ -z "${p[i]}" ]]; then
      printlog "${D_VARS_L[0]} of instance '${INSTANCES[i]}' is not set, fallback to the global setting." warn
      eval "p[i]=\"\$(_checkparentpath '${p_d}' '${u[i]}')\""
    else
      eval "p[i]=\$(_checkparentpath '${p[i]}' '${u[i]}' ${i})"
    fi
  done

  # replace username/groupname to uid/gid to avoid unforeseen errors
  local -a ui gi
  for (( i = 0; i < ${ilen}; ++i )); do
    eval "CONFIGS_${i}[${D_VARS_L[0]}]='${p[i]}'"
    if [[ ! "${u[i]}" =~ ^[[:digit:]]+$ ]]; then
      eval "ui[${i}]=\$(_getent passwd ${u[i]} | { IFS=':'; read _ _ un _; echo -n \${un:-999999}; })"
    fi
    eval "CONFIGS_${i}[${D_VARS_L[1]}]='${ui[i]:=${u[i]}}'"
    if [[ ! "${g[i]}" =~ ^[[:digit:]]+$ ]]; then
      eval "gi[${i}]=\$(_getent group ${g[i]} | { IFS=':'; read _ _ un _; echo -n \${un:-999999}; })"
    fi
    eval "CONFIGS_${i}[${D_VARS_L[2]}]='${gi[i]:=${g[i]}}'"
  done

  #check user and groups
  if [[ "${CUSER}" == 0 ]]; then
    return
  fi
  local -a otherusers othergroups
  for (( i = 0; i < ${ilen}; ++i )); do
    #check user
    if [[ "${CUSER}" != "${ui[i]}" ]]; then
      eval "otherusers[${i}]=${i}"
    fi
    #check groups
    if [[ ! "${gi[i]}" =~ ${CGROUPS} ]]; then
      eval "othergroups[${i}]=${i}"
    fi
  done
  if [[ ${#otherusers[@]} > 0 || ${#othergroups[@]} > 0 ]]; then
    printlog "Ownership cannot be handled!" warn
    if [[ ${#otherusers[@]} > 0 ]]; then
      printlog "  file owner:" warn
      for i in "${otherusers[@]}"; do
        printlog "    '${u[i]}' for instance: '${INSTANCES[i]}'" warn
        if [[ "${ur[i]}" != "${u[i]}" ]]; then
          printlog '      \`-- (which inherited from global settings)' warn
        fi
      done
    fi
    if [[ ${#othergroups[@]} > 0 ]]; then
      printlog "  file group:" warn
      for i in "${othergroups[@]}"; do
        printlog "    '${g[i]}' for instance: '${INSTANCES[i]}'" warn
        if [[ "${gr[i]}" != "${g[i]}" ]]; then
          printlog '      \`-- (which inherited from global settings)' warn
        fi
      done
    fi
    if [[ ${CMD} != config ]]; then #TODO
      fatalerr "You should run z16, set the instance or run ssh with a proper user! Bye~"
    fi
  fi
}

# vim: et:ts=2:sts:sw=2
