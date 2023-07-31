#!/bin/bash

export PATH=${PATH}:${BASH_BIN}
export PATH=${PATH}:${BASH_BIN}
export PATH=${PATH}:${PWD}/lib

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-bash.sh
. ${BASH_BIN}/lib-docker.sh
. ${BASH_BIN}/lib-selector.sh
. ${BASH_BIN}/lib-database.sh
#. ${BASH_BIN}/lib-actions.sh


# . ${INSTALLER_DIR}/lib/util-prepare.sh
# . ${INSTALLER_DIR}/lib/util-selectors.sh
. ${INSTALLER_DIR}/lib/util-runner.sh


function __private_runnerMenu()
{
  clearTerm
  __private_print_os_information
  __runner_menu_environment=${1} 
  __runner_menu_target=${2}

  options=(Quit)
  options+=(Docker-Configure)
  options+=(Docker-Build-SRV)
  options+=(Docker-Build-MCS)
  options+=(Docker-Build-ADM)
  options+=(Docker-Reset)
  options+=(Docker-List)
  options+=(Database-Update)
  options+=(Database-DDL-Maker)
  options+=(Database-PGPass)
  options+=(DNS-Options)
  options+=(Command-Utils)
  echM $'\n'"Docker managment tools"$'\n'
  PS3=$'\n'"Choose option:"
  select opt in "${options[@]}"
  do
    if [[ ${opt} == "Quit" ]]; then
      exit 0
    fi
    echo ""
    echo "Action selected: [${opt}]"
    echo ""
    if [[ ${opt} == "Docker-Configure" ]]; then
      dockerConfigure ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Docker-Build-SRV" ]]; then
      dockerSRVMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Docker-Build-MCS" ]]; then
      dockerMCSMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Docker-Build-ADM" ]]; then
      dockerADMMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Docker-List" ]]; then
      dockerList ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Docker-Reset" ]]; then
      dockerReset ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Database-Update" ]]; then
      databaseUpdate ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Database-DDL-Maker" ]]; then
      databaseDDLMaker ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "DNS-Options" ]]; then
      systemDNSOptions ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Database-PGPass" ]]; then
      selectorPGPass ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Command-Utils" ]]; then
      selectorCommands ${__runner_menu_environment} ${__runner_menu_target}
    else
      echR "Invalid option ${opt}"
    fi
    echB
    echG "[ENTER] to continue"
    echG
    read
    return 1
  done
}

# main system
function runnerMain()
{
  clearTerm
  export STACK_TARGET=${__public_target}
  export STACK_ENVIRONMENT=${__public_environment}
  utilInitialize "$@"

  if [[ ${PUBLIC_RUNNER_MODE} == test ]]; then
    ./runner-test.sh
    exit 0;
  fi

  clearTerm

  dockerSwarmVerify
  if ! [ "$?" -eq 1 ]; then
    echR "Invalid dockerSwarmVerify"
    exit 0
  fi

  if [[ ${__public_target} == "" ]]; then
    selectorCustomer 1
    if ! [ "$?" -eq 1 ]; then
      echR "Invalid selectorCustomer"
      exit 0
    fi
    export __public_target=${__selector}
  fi

  if [[ ${__public_environment} == "" ]]; then
    selectorEnvironment 1
    if ! [ "$?" -eq 1 ]; then
      echR "Invalid selectorEnvironment"
      exit 0
    fi
  fi
  export __public_environment=${__selector}


  export STACK_TARGET=${__public_target}
  export STACK_ENVIRONMENT=${__public_environment}
  export STACK_PREFIX=${STACK_ENVIRONMENT}-${STACK_TARGET}
  
  utilPrepareInit

  if ! [ "$?" -eq 1 ]; then
    exit 0
  fi

  databasePrepare ${STACK_ENVIRONMENT} ${STACK_APPLICATIONS_DATA_DB_DIR}
  if ! [ "$?" -eq 1 ]; then
    echR "Invalid databasePrepare"
    exit 0;
  fi

  while :
  do
    __private_runnerMenu ${__public_environment} ${__public_target}
  done
}

runnerMain "$@"