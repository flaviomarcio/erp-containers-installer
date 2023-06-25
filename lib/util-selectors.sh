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

function selectDeployOpt()
{
  clearTerm
  echo $'\n'"Deploy mode menu"$'\n'
  export STACK_DEPLOY_MODE=all
  PS3='Please select a deploy mode: '
  options=(Back all build deploy)
  select opt in "${options[@]}"
  do
    if [[ ${opt} == "back" ]]; then
      return 2;
    else
      export STACK_DEPLOY_MODE=${opt}
      return 1;
    fi    
  done
  return 0;
}

function selectProject()
{
  clearTerm
  echo $'\n'"Project menu"$'\n'
  PS3='Please select a project: '
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
  clearTerm
  echo $'\n'"Action menu"$'\n'
  PS3='Please select a action: '
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

function selectCustomer()
{
  export PUBLIC_STACK_TARGET_FILE=${HOME}/applications/stack_targets.env
  if [[ -f ${PUBLIC_STACK_TARGET_FILE} ]]; then
    options=$(cat ${PUBLIC_STACK_TARGET_FILE})
    options="quit company ${options}"
  else
    options="quit company"
  fi
  options=(${options})

  clearTerm
  echo $'\n'"Customer menu"$'\n'
  PS3="Choose a customer: "
  select opt in "${options[@]}"
  do
    if [[ ${opt} == "quit" ]]; then
      return 2
    else
      export STACK_TARGET=${opt}
      return 1
    fi
  done
  return 0;
}

function selectEnvironment()
{
  clearTerm
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
  logMethod ${1} "action: ${STACK_ACTION}, project: ${STACK_PROJECT}"
  
  export STACK_ACTION=${2}
  export STACK_PROJECT=${3}

  RUN_FILE=${STACK_INSTALLER_BIN_DIR}/${STACK_ACTION}
  runSource "$(incInt ${1})" ${RUN_FILE} 
  logFinished ${1} "runOption"
}