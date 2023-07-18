#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh

function getProjects()
{
  if [[ ${STACK_ACTION} == "deploy-db" || ${STACK_ACTION} == "deploy-db-drop"  ]]; then
    OPTDIR=${STACK_APPLICATIONS_DATA_DB_DIR}
  else
    OPTDIR=${STACK_APPLICATIONS_PROJECT_DIR}
  fi
  echo -n $(ls ${OPTDIR} | sort)
}

function selectProject()
{
  export STACK_INSTALL_BUILD_ARGS=
  clearTerm
  echM $'\n'"Project menu"$'\n'
  PS3="Choose a option: "

  options=(back all $(getProjects))

  select opt in "${options[@]}"
  do
    if [[ ${opt} == "back" ]]; then
      return 2;
    elif [[ ${opt} == "all" ]]; then
      STACK_PROJECT=$(getProjects)
    else
      STACK_PROJECT=${opt}
    fi    
    return 1;
  done

  return 0;
}

function getActions()
{
  echo -n $(ls ${STACK_INSTALLER_BIN_DIR} | sort)
}

function selectAction()
{
  export STACK_INSTALL_BUILD_ARGS=
  clearTerm
  echM $'\n'"Action menu"$'\n'
  PS3="Choose a option: "

  options=(quit $(getActions))

  select opt in "${options[@]}"
  do
    if [[ ${opt} == "quit" ]]; then
      return 2
    else
      export STACK_ACTION=${opt}
      return 1
    fi
  done

  return 0;
}

function runOption()
{
  logStart ${1} "runOption"
  logMethod ${1} "action: ${STACK_ACTION}, project: ${STACK_PROJECT}"
  
  export STACK_ACTION=${2}
  export STACK_PROJECT=${3}

  RUN_FILE=${STACK_INSTALLER_BIN_DIR}/${STACK_ACTION}
  runSource "$(incInt ${1})" ${RUN_FILE} 
  logFinished ${1} "runOption"
}