#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh

function selectProject()
{
  echo ""  
  if [[ ${STACK_ACTION} == "deploy-db" || ${STACK_ACTION} == "deploy-db-drop"  ]]; then
    OPTDIR=${STACK_APPLICATIONS_DB_DIR}
  else
    OPTDIR=${STACK_APPLICATIONS_PROJECT_DIR}
  fi
  options=(back $(ls ${OPTDIR}))    
  PS3='Please select a project: '
  select opt in "${options[@]}"
  do
    if [[ ${opt} == "back" ]]; then
      return 0;
    fi
    STACK_PROJECT=${opt}
    break;
  done
  return 1;
}

function selectAction()
{
  echo ""
  options=(quit $(ls ${STACK_INSTALLER_BIN_DIR}))
  PS3='Please select a action: '
  select opt in "${options[@]}"
  do
    if [[ ${opt} == "quit" ]]; then
      return 0
    fi
    export STACK_ACTION=${opt}
    break
  done
  return 1;  
}

function selectEnviroment()
{
  echo $'\n'"Environment menu"$'\n'
  PS3="Choose a environment: "
  
  options=(testing development staging production quit)

  select opt in "${options[@]}"
  do
    export STACK_ENVIRONMENT=${opt}
    case ${opt} in
        "development")
          break;
            ;;
        "testing")
          break;
            ;;
        "stating")
          break;
            ;;
        "production")
          break;
            ;;
        "quit")
          return 0;
            ;;
        *) echo "invalid option ${opt}";
    esac
  done
  return 1;
}

function runOption()
{
  logStart ${1} "runOption"
  logMethod ${1} "action: ${STACK_ACTION}"
  logMethod ${1} "project: ${STACK_PROJECT}"
  
  export STACK_ACTION=${2}
  export STACK_PROJECT=${3}

  RUN_FILE=${STACK_INSTALLER_BIN_DIR}/${STACK_ACTION}
  runSource "$(incInt ${1})" ${RUN_FILE} 
  logFinished ${1} "runOption"
}