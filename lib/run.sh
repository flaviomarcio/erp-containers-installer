#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh
. ${INSTALLER_DIR}/lib/util-selectors.sh

function runInstaller()
{
  selectEnvironment
  while : 
  do
    selectAction    
  done
}
