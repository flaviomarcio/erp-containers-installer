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

function __applicationVerify()
{
  local __apps=(jq yp tar zip)
  local __app=
  for __app in ${__apps[*]}; do
    if [[ $(which jq) == "" ]]; then
      local __not_found=0
      break
    fi
  done

  if [[ ${__not_found} == 0 ]]; then
    echo ""
    echR "Applications not found"
    echB "  Execute to continue"
    echY "    sudo apt install -y ${__apps[*]}"
    return 0
  fi

  return 1
}

function __private_check_is_test()
{
  local __arg=
  for __arg in "$@"
  do
    if [[ ${__arg} == "--test" ]]; then
      return 1;
    fi
  done
  return 0;
}

function __private_check_is_pipeline()
{
  local __arg=
  for __arg in "$@"
  do
    if [[ ${__arg} == "--pipeline" ]]; then
      return 1;
    fi
  done
  return 0;
}

function __runnerPrepare()
{
  clearTerm
  __applicationVerify
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __applicationVerify"
    return 0
  fi
  utilInitialize "$@"
  dockerSwarmVerify
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling dockerSwarmVerify"
    return 0
  fi

  if [[ ${__public_target} == "" ]]; then
    selectorCustomer 1
    if ! [ "$?" -eq 1 ]; then
      echR "Invalid selectorCustomer"
      echR "  fail on calling selectorCustomer"
      return 0
    fi
    export __public_target=${__selector}
  fi

  if [[ ${__public_environment} == "" ]]; then
    selectorEnvironment 1
    if ! [ "$?" -eq 1 ]; then
      echR "  fail on calling selectorEnvironment"
      return 0
    fi
    export __public_environment=${__selector}
  fi

  utilPrepareInit "${__public_environment}" "${__public_target}"

  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling utilPrepareInit"
    return 0
  fi

  databasePrepare ${__public_environment} ${STACK_APPLICATIONS_DATA_DB_DIR}
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling databasePrepare"
    return 0
  fi

  scriptsPrepare ${__public_environment} ${STACK_APPLICATIONS_DATA_SCRIPT_DIR}
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling scriptsPrepare"
    return 0
  fi
  return 1
}

function __private_runnerMenuOptions()
{
  __runnerPrepare
  if ! [ "$?" -eq 1 ]; then
    echR "fail on call __runnerPrepare"
    return 0
  fi
  __private_print_os_information
  echC "  - Application Dir: ${COLOR_YELLOW}${STACK_APPLICATIONS_DIR}"
  __runner_menu_environment=${1} 
  __runner_menu_target=${2}

  options=(Quit)
  options+=(Docker-List)
  options+=(Docker-Build-SRV)
  options+=(Docker-Build-MCS)
  options+=(Docker-Build-ADM)
  options+=(Vault-options)
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
    elif [[ ${opt} == "Vault-options" ]]; then
       vaultMain ${__runner_menu_environment} ${__runner_menu_target}
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

function __private_runnerMenu()
{
  local __public_environment=${1}
  local __public_target=${2}
  while :
  do
    __private_runnerMenuOptions ${__public_environment} ${__public_target}
  done
}


function __private_pipeline_runner()
{  
  unset PIPELINE_ENVIRONMENT
  unset PIPELINE_TARGET
  unset PIPELINE_NAME

  unset __pipe_arg_key
  unset __pipe_arg_val

  local __pipe_arg_key_list=()
  local __pipe_arg=
  for __pipe_arg in "$@"
  do
    unset __pipe_arg_key
    unset __pipe_arg_val
    if [[ ${__pipe_arg} != --pipeline-* ]]; then
      continue;
    fi
    local __pipe_arg_key=$(echo ${__pipe_arg} | awk -F= '{print $1}')
    local __pipe_arg_val=$(echo ${__pipe_arg} | awk -F= '{print $2}')

    local __pipe_arg_key=$(echo ${__pipe_arg_key} | sed 's/--//g' | sed 's/-/_/g')
    local __pipe_arg_key=$(toUpper "${__pipe_arg_key}")

    export ${__pipe_arg_key}="\"${__pipe_arg_val}\""
    local __pipe_arg_key_list+=(${__pipe_arg_key})
  done  
  __runnerPrepare "$@"
  if ! [ "$?" -eq 1 ]; then
    echR "fail on call __runnerPrepare"
    return 0
  fi
  echM "Pipelines"
  echB "  Args:"
  local __key=
  for __key in "${__pipe_arg_key_list[@]}"
  do
    echC "    - ${__key}: ${COLOR_YELLOW_B}${!__key}"
  done

  if [[ ${PIPELINE_ENVIRONMENT} == "" ]]; then
    echR "Invalid --pipeline-environment"
    return 0
  fi

  if [[ ${PIPELINE_TARGET} == "" ]]; then
    echR "Invalid --pipeline-target"
    return 0
  fi
 
  if [[ ${PIPELINE_NAME} == "" ]]; then
    echR "Invalid --pipeline-name"
    return 0
  fi

  return 1
}

# main system
function runnerMain()
{
  clearTerm
  __private_check_is_pipeline "$@"
  if [ "$?" -eq 1 ]; then
    __private_pipeline_runner "$@"
    if ! [ "$?" -eq 1 ]; then
      echR "fail on call __private_check_is_pipeline"
    fi
    exit 0
  fi

  __private_check_is_test "$@"
  if [ "$?" -eq 1 ]; then
    ./runner-test.sh
    exit 0
  fi

  __runnerPrepare "$@"
  if ! [ "$?" -eq 1 ]; then
    echR "fail on call __runnerPrepare"
    return 0
  fi

  __private_runnerMenu ${__public_environment} ${__public_target}
}

runnerMain "$@"