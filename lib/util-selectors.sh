#!/bin/bash

. ${INSTALLER_DIR}/lib/util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh

function selectProject()
{
  echo ""  
  if [[ ${STACK_ACTION} == "deploy-db" || ${STACK_ACTION} == "deploy-db-drop"  ]]; then
    OPTDIR=${STACK_APPLICATION_DB_DIR}
  else
    OPTDIR=${STACK_APPLICATION_PROJECT_DIR}
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
  options=(quit $(ls ${STACK_BIN_DIR}))
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
