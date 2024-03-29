#!/bin/bash

. lib-docker.sh
. lib-database.sh
. lib-selector.sh
. lib-system.sh
. lib-deploy.sh
. lib-scripts.sh
. lib-vault.sh
. util-prepare.sh

function dockerBuild()
{
  export STACK_TYPE=${1}
  export STACK_NAME=${2}
  dockerNetworkConfigure
  dockerBuildCompose ${STACK_TYPE} ${STACK_NAME}
  #cleanup
  if [ "$?" -eq 1 ]; then
    unset STACK_TYPE
    unset STACK_NAME
    return 1
  fi
  unset STACK_TYPE
  unset STACK_NAME
  return 0
}

function dockerSRVMain()
{
  return 1
  echG "Deploying default services"
  echG
  export STACK_TYPE=srv
  dockerBuild ${STACK_TYPE}
  if ! [ "$?" -eq 1 ]; then
    echB
    echR "[FAIL]dockerBuild"
  fi
  systemETCHostApply ${STACK_PREFIX}
  return 0
}

function dockerADMMain()
{
  return 1
  echG "Deploying admin/debian"
  echG
  export STACK_TYPE=adm
  dockerBuild ${STACK_TYPE}
  if ! [ "$?" -eq 1 ]; then
    echB
    echR "[FAIL]dockerBuild"
  fi
  systemETCHostApply ${STACK_PREFIX}
  return 0
}

function dockerMCSMain()
{
  local __dk_mcs_environment=${STACK_ENVIRONMENT} 
  local __dk_mcs_target=${STACK_TARGET}
  local __dk_mcs_fail_detected=false
  local __dk_mcs_project_dir=${STACK_APPLICATIONS_PROJECT_DIR}

  __private_print_os_information
  local __dk_mcs_projects=$(echo -n $(ls ${__dk_mcs_project_dir}) | sort)
  selectorBack "Project menu" "${__dk_mcs_projects}" 
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  local __dk_mcs_projects=(${__selector})

  clearTerm
  echG "Build/deploy options for:"
  local __dk_mcs_project=
  for __dk_mcs_project in "${__dk_mcs_projects[@]}"
  do
  echC "  - ${__dk_mcs_project}"
  done
  echC
  
  selectorBuildOption
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  local __dk_mcs_build_option=${__selector}

  clearTerm
  echG "Deploying micro services"
  echC "  - Build option: [${__dk_mcs_build_option}]"
  echC
  local __dk_mcs_project=
  for __dk_mcs_project in "${__dk_mcs_projects[@]}"
  do
    local __dk_mcs_stack_env=${__dk_mcs_project_dir}/${__dk_mcs_project}

    echM "  Environment preparing "
    echY "    - stack envs"
    prepareStackForDeploy "${__dk_mcs_project_dir}" "${__dk_mcs_project}"
    if ! [ "$?" -eq 1 ]; then
      echY "      fail on calling prepareStackForDeploy, ${__func_return}"
      local __dk_mcs_fail_detected=true
      break
    fi

    local __dk_mcs_git_repository=${APPLICATION_GIT}
    local __dk_mcs_git_branch=${APPLICATION_GIT_BRANCH}
    local __dk_mcs_git_project_file=${APPLICATION_GIT_PROJECT_FILE}
    local __dk_mcs_binary_name=${APPLICATION_DEPLOY_BINARY_NAME}
    #build dir
    local __dk_mcs_builder_base_dir="${HOME}/build/pipelines/${__dk_mcs_environment}-${__dk_mcs_target}/app"
    local __dk_mcs_builder_dir="${__dk_mcs_builder_base_dir}/${__dk_mcs_project}"
    local __dk_mcs_bin_dir="${__dk_mcs_builder_base_dir}/${STACK_PREFIX}/bin"
    
    rm -rf ${__dk_mcs_builder_dir}
    mkdir -p ${__dk_mcs_builder_dir}
    mkdir -p ${__dk_mcs_bin_dir}

    local __dk_mcs_dk_yml=${STACK_INSTALLER_DOCKER_COMPOSE_DIR}/${APPLICATION_STACK}.yml
    local __dk_mcs_dk_file=${STACK_INSTALLER_DOCKER_FILE_DIR}/${APPLICATION_STACK}.dockerfile
    local __dk_mcs_dk_image=${APPLICATION_DEPLOY_IMAGE}    

    echY "    - docker envs"
    local __deploy_dck_compose_name=$(basename ${__dk_mcs_dk_yml} | sed 's/\.yml//g')

    unset __deploy_dck_env_tags
    local __deploy_dck_env_tags_headers=(env docker)
    local __deploy_dck_env_tags_header=
    for __deploy_dck_env_tags_header in "${__deploy_dck_env_tags_headers[@]}"
    do
      local __deploy_dck_env_tags_defaults=("resource.${__dk_mcs_environment}" "default.${__dk_mcs_environment}" "${APPLICATION_STACK}")
      local __deploy_dck_env_tags_default=
      for __deploy_dck_env_tags_default in "${__deploy_dck_env_tags_defaults[@]}"
      do
        local __deploy_dck_env_tags_name="${__deploy_dck_env_tags_header}.${__deploy_dck_env_tags_default}"
        local __deploy_dck_env_tags="${__deploy_dck_env_tags} ${__deploy_dck_env_tags_name}"
        export APPLICATION_ENV_TAGS=$(echo ${APPLICATION_ENV_TAGS} | sed "s/${__deploy_dck_env_tags_name}//g" | sed "s/  / /g")
      done
    done
    #application args
    local __deploy_dck_env_tags="${__deploy_dck_env_tags} ${APPLICATION_ENV_TAGS}"

    deployPrepareEnvFile "${STACK_APPLICATIONS_DATA_ENV_JSON_FILE}" "${__dk_mcs_builder_dir}" "${__deploy_dck_env_tags}"
    if ! [ "$?" -eq 1 ]; then
      echR "fail on calling deployPrepareEnvFile"
      local __dk_mcs_fail_detected=true
      break
    else
      local __dk_mcs_dk_env_file=${__func_return}
    fi
    #envsReplaceFile ${__dk_mcs_dk_yml}
    echG "  Finished"

    local __dk_mcs_dep_dir="${STACK_APPLICATIONS_DATA_SRC_DIR}/${__dk_mcs_project} ${STACK_INSTALLER_DOCKER_CONF_DIR}/${APPLICATION_STACK}"

    if [[ ${__dk_mcs_git_branch} == "" ]]; then
      local __dk_mcs_git_branch=master
    fi

    deploy \
          "${__dk_mcs_environment}" \
          "${__dk_mcs_target}" \
          "${__dk_mcs_project}" \
          "${__dk_mcs_builder_dir}" \
          "${__dk_mcs_build_option}" \
          "${__dk_mcs_git_repository}" \
          "${__dk_mcs_git_branch}" \
          "${__dk_mcs_git_project_file}" \
          "${__dk_mcs_dk_image}" \
          "${__dk_mcs_dk_file}" \
          "${__dk_mcs_dk_yml}" \
          "${__dk_mcs_dk_env_file}" \
          "${__dk_mcs_bin_dir}" \
          "${__dk_mcs_binary_name}" \
          "${__dk_mcs_dep_dir}"
    if ! [ "$?" -eq 1 ]; then
      echR "  fail on calling deploy: ${__func_return} "
      local __dk_mcs_fail_detected=true
      break
    fi
  done

  echG "  Finished"    
  if [[ ${__dk_mcs_fail_detected} == true ]]; then
    echR "  =============================  "
    echR "  ********FAIL DETECTED********  "
    echR "  ********FAIL DETECTED********  "
    echR "  =============================  "    
    return 0;
  fi
  systemETCHostApply ${STACK_PREFIX}
  return 1;
}

function vaultMain()
{
  stackVaultLogoff
  stackVaultLogin
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  while :
  do
    clearTerm
    echM "Information"
    echG "  -stack"
    echC "    - target: ${STACK_TARGET}"
    echC "    - environment: ${STACK_ENVIRONMENT}"
    echG "  -vault"
    echC "    - uri: ${STACK_VAULT_URI}"
    echC "    - method: ${STACK_VAULT_METHOD}"
    echC "    - token: ${STACK_VAULT_TOKEN}"
    echC "    - token-deploy: ${STACK_VAULT_TOKEN_DEPLOY}"
    echC "    - app-role-id: ${STACK_VAULT_APP_ROLE_ID}"
    echC "    - app-role-secret: ${STACK_VAULT_APP_ROLE_SECRET}"
    echC "    - import: ${STACK_VAULT_IMPORT}"

    selector "Vault menu" "Quit Pull Push List" false
    local opt=${__selector}
    if [[ ${opt} == "Quit" ]]; then
      break
    elif [[ ${opt} == "Pull" ]]; then
      stackVaultPull
    elif [[ ${opt} == "Push" ]]; then
      stackVaultPush
    elif [[ ${opt} == "List" ]]; then
      stackVaultList
    else
      continue;
    fi
    if ! [ "$?" -eq 1 ]; then
      echR "fail on calling option[${opt}]: ${__func_return}"
      read
    fi
  done
  stackVaultLogoff
  return 1
}

function databaseUpdateMain()
{
  local __environment=${1}
  if [[ ${__environment} != "testing" && ${__environment} != "development"  ]]; then
    echo ""
    echR "  =============================  "
    echR "  ***********CRITICAL**********  "
    echR "  =============================  "
    echo ""
    echY "  =============================  "
    echY "  *******DATABASE UPDATE*******  "
    echY "  =============================  "
    echo ""
    selectorWaitSeconds 3 "" "${COLOR_YELLOW_B}"

    selectorYesNo "Database update"
    if ! [ "$?" -eq 1 ]; then
      return 0
    fi
    echo ""
    echR "  =============================  "
    echR "  ***********CRITICAL**********  "
    echR "  =============================  "
    echo ""
    echY "  =============================  "
    echY "  *******DATABASE UPDATE*******  "
    echY "  =============================  "
    echo ""
    selectorWaitSeconds 10 "" "${COLOR_YELLOW_B}"
  fi

  databaseUpdateExec
  return 0
}

function databaseDDLMakerMain()
{
  databaseDDLMakerExec
  return 0
}

function scriptsExecuteMain()
{
  local __environment=${1}
  if [[ ${__environment} != "testing" && ${__environment} != "development"  ]]; then
    echo ""
    echR "  =============================  "
    echR "  ***********CRITICAL**********  "
    echR "  =============================  "
    echo ""
    echY "  =============================  "
    echY "  *******DATABASE UPDATE*******  "
    echY "  =============================  "
    echo ""
    selectorWaitSeconds 3 "" "${COLOR_YELLOW_B}"

    selectorYesNo "Script execute"
    if ! [ "$?" -eq 1 ]; then
      return 0
    fi
    echo ""
    echR "  =============================  "
    echR "  ***********CRITICAL**********  "
    echR "  =============================  "
    echo ""
    echY "  =============================  "
    echY "  *******DATABASE UPDATE*******  "
    echY "  =============================  "
    echo ""
    selectorWaitSeconds 10 "" "${COLOR_YELLOW_B}"
  fi

  scriptsExecute
  return 0
}

function systemDNSOptions()
{
  selector "DNS options" "Back print etc-hosts-apply etc-hosts-remove"
  if [[ ${__selector} == "etc-hosts-apply" || ${__selector} == "etc-hosts-remove" ]]; then

    if [[ ${STACK_ENVIRONMENT} == "production" ]]; then
      echo ""
      echR "  =============================  "
      echR "  ***********CRITICAL**********  "
      echR "  =============================  "
      echo ""
      echY "  =============================  "
      echY "  *********HOSTS UPDATE********  "
      echY "  =============================  "
      echo ""

      selectorYesNo "Change hosts"
      if ! [ "$?" -eq 1 ]; then
        return 1
      fi
      selectorWaitSeconds 5 "" "${COLOR_YELLOW_B}"
    fi
    if [[ ${__selector} == "etc-hosts-apply" ]]; then
      systemETCHostApply ${STACK_PREFIX}
    else
      systemETCHostRemove ${STACK_PREFIX}
    fi

  elif [[ ${__selector} == "print" ]]; then
    systemETCHostPrint
    return 0
  fi 
  return 1
}

function userManagmentMain()
{
  userManagmentMenu
}