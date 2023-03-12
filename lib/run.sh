#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${STACK_INSTALLER_DIR}/lib/util-prepare.sh
. ${STACK_INSTALLER_DIR}/lib/util-selectors.sh

function runInstaller()
{
  selectEnviroment
  while : 
  do
    selectAction    
  done
}
