#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${BASH_BIN}/lib-selector.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh
. ${INSTALLER_DIR}/lib/util-selectors.sh

function runInstaller()
{
  selectorEnvironment
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  while : 
  do
    export STACK_INSTALL_BUILD_ARGS=
    echo -n $(ls ${STACK_INSTALLER_BIN_DIR} | sort)
    __private_print_os_information
    selectorQuit "Action menu" "$(getActions)" 
    if [ "$?" -eq 2 ]; then
      exit 0
    elif ! [ "$?" -eq 1 ]; then
      continue
    else
      export STACK_ACTION=${__selector}
      echo "STACK_ACTION==${STACK_ACTION}"
      read
    fi

  done
}
