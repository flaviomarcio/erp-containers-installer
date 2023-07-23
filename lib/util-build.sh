#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh

function buildProjectPrepare()
{
  if [[ ${2} != "" && ${3} != "" ]]; then
    export STACK_ACTION=${2}
    export STACK_PROJECT=${3}
  fi
  
  export STACK_APPLICATIONS_RUN=${STACK_APPLICATIONS_PROJECT_DIR}/${STACK_PROJECT}
  RUN_FILE=${STACK_APPLICATIONS_RUN}

  runSource "$(incInt ${1})" ${RUN_FILE}
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  prepareStack
  return 1;
}
