#!/bin/bash

export PATH=${PATH}:${BASH_BIN}
export PATH=${PATH}:${BASH_BIN}
export PATH=${PATH}:${PWD}/lib

if [[ ${BASH_BIN} == "" ]]; then
  BASH_BIN="$(dirname ${PWD})/bash-bin"
fi

if [[ ${INSTALLER_LIB} == "" ]]; then
  INSTALLER_DIR=${PWD}
fi

export INSTALLER_LIB=${INSTALLER_DIR}/lib

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-docker.sh
. ${BASH_BIN}/lib-selector.sh
. ${BASH_BIN}/lib-database.sh
. ${INSTALLER_LIB}/util-runner.sh


function __private_runnerMenu()
{
  clearTerm
  __private_print_os_information
  __runner_menu_environment=${1} 
  __runner_menu_target=${2}

  options=(Quit)
  options+=(Docker-List)
  options+=(Docker-Build-SRV)
  options+=(Docker-Build-MCS)
  options+=(Docker-Build-ADM)
  options+=(Database-Update)
  #options+=(Database-DDL-Maker)
  #options+=(Database-PGPass)
  options+=(Script-execute)
  options+=(User-Management)
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
    if [[ ${opt} == "Docker-List" ]]; then
      dockerList ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Docker-Build-SRV" ]]; then
      dockerSRVMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Docker-Build-MCS" ]]; then
      dockerMCSMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Docker-Build-ADM" ]]; then
      dockerADMMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Database-Update" ]]; then
      databaseUpdateMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Database-DDL-Maker" ]]; then
      databaseDDLMakerMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Database-PGPass" ]]; then
      selectorPGPass ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "Script-execute" ]]; then
      scriptsExecuteMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "User-Management" ]]; then
      userManagmentMain ${__runner_menu_environment} ${__runner_menu_target}
    elif [[ ${opt} == "DNS-Options" ]]; then
      systemDNSOptions ${__runner_menu_environment} ${__runner_menu_target}
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

  utilInitialize "$@"

  if [[ ${PUBLIC_RUNNER_MODE} == test ]]; then
    ./runner-test.sh
    exit 0;
  fi

  clearTerm

  dockerSwarmVerify
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling dockerSwarmVerify"
    exit 0
  fi

  if [[ ${__public_target} == "" ]]; then
    selectorCustomer 1
    if ! [ "$?" -eq 1 ]; then
      echR "Invalid selectorCustomer"
      echR "  fail on calling selectorCustomer"
      exit 0
    fi
    export __public_target=${__selector}
  fi

  if [[ ${__public_environment} == "" ]]; then
    selectorEnvironment 1
    if ! [ "$?" -eq 1 ]; then
      echR "  fail on calling selectorEnvironment"
      exit 0
    fi
    export __public_environment=${__selector}
  fi

  utilPrepareInit "${__public_environment}" "${__public_target}"

  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling utilPrepareInit"
    exit 0
  fi

  databasePrepare ${__public_environment} ${STACK_APPLICATIONS_DATA_DB_DIR}
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling databasePrepare"
    exit 0;
  fi

  scriptsPrepare ${__public_environment} ${STACK_APPLICATIONS_DATA_SCRIPT_DIR}
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling scriptsPrepare"
    exit 0;
  fi

  while :
  do
    __private_runnerMenu ${__public_environment} ${__public_target}
  done
}

runnerMain "$@"