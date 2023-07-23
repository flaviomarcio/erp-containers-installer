#!/bin/bash

. lib-bash.sh
. lib-docker.sh
. lib-database.sh
. lib-selector.sh
. lib-system.sh
. lib-deploy.sh

. util-prepare.sh
. util-build.sh

function dockerBuild()
{
  export STACK_TYPE=${1}
  export STACK_NAME=${2}
  dockerNetworkConfigure
  dockerBuildCompose ${STACK_TYPE} ${STACK_NAME}
  #cleanup
  if [ "$?" -eq 1 ]; then
    export STACK_TYPE= 
    export STACK_NAME=
    return 1
  fi
  export STACK_TYPE= 
  export STACK_NAME=
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
    echR "[FAIL]dockerBuildCompose"
  fi
  systemETCHostApply
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
    echR "[FAIL]dockerBuildCompose"
  fi
  systemETCHostApply
  return 0
}

function dockerMCSMain()
{
  __dk_mcs_environment=${1} 
  __dk_mcs_target=${2}
  FAIL_DETECTED=false

  utilPrepareInit 1
  __dk_mcs_project_dir=${STACK_APPLICATIONS_PROJECT_DIR}

  __private_print_os_information
  __dk_mcs_projects=$(echo -n $(ls ${__dk_mcs_project_dir}) | sort)
  selectorBack "Project menu" "${__dk_mcs_projects}" 
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  __dk_mcs_projects=(${__selector})

  clearTerm
  echG "Build/deploy options for:"
  for __dk_mcs_project in "${__dk_mcs_projects[@]}"
  do
  echC "  - ${__dk_mcs_project}"
  done
  echC
  
  selectorBuildOption
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  __dk_mcs_build_option=${__selector}

  clearTerm
  echG "Deploying micro services"
  echC "  - Build option: [${__dk_mcs_build_option}]"
  echC
  
  for __dk_mcs_project in "${__dk_mcs_projects[@]}"
  do
    export STACK_PROJECT=${__dk_mcs_project}

    __dk_mcs_stack_env=${__dk_mcs_project_dir}/${__dk_mcs_project}

    echM "  Environment preparing "
    echY "    - source ${__dk_mcs_stack_env}"
    source ${__dk_mcs_stack_env};
    echY "    - stack envs"
    prepareStack

    __dk_mcs_git_repository=${APPLICATION_GIT}
    __dk_mcs_git_branch=${APPLICATION_GIT_BRANCH}
    __dk_mcs_builder_dir="${HOME}/build/${STACK_PREFIX}-${__dk_mcs_project}"
    __dk_mcs_bin_dir="${HOME}/build/${STACK_PREFIX}/bin"
    rm -rf ${__dk_mcs_builder_dir}

    # __dk_mcs_stack_base_start_dir=${STACK_APPLICATIONS_DATA_CONF_DIR}/${APPLICATION_STACK}
    # ls -l ${__dk_mcs_stack_base_start_dir}
    # read
    # if [[ -d ${__dk_mcs_stack_base_start_dir} ]]; then
    #   cp -rf ${__dk_mcs_stack_base_start_dir} ${__dk_mcs_builder_dir}
    # else
    # fi
    mkdir -p ${__dk_mcs_builder_dir}
    mkdir -p ${__dk_mcs_bin_dir}

    __dk_mcs_dk_yml=${STACK_INSTALLER_DOCKER_COMPOSE_DIR}/${APPLICATION_STACK}.yml
    __dk_mcs_dk_file=${STACK_INSTALLER_DOCKER_FILE_DIR}/${APPLICATION_STACK}.dockerfile
    __dk_mcs_dk_image=${APPLICATION_DEPLOY_IMAGE}    

    echY "    - docker envs"
    __deploy_dck_compose_name=$(basename ${__dk_mcs_dk_yml} | sed 's/\.yml//g')
    __deploy_dck_env_tags=${APPLICATION_ENV_TAGS}
    __deploy_dck_env_tags="docker.default docker.${__deploy_dck_compose_name} docker.${APPLICATION_STACK} ${__deploy_dck_env_tags}"
    __deploy_dck_env_tags="env.default env.${__deploy_dck_compose_name} env.${APPLICATION_STACK} ${__deploy_dck_env_tags}"
    deployPrepareEnvFile "${STACK_APPLICATIONS_DATA_ENV_JSON_FILE}" "${__dk_mcs_builder_dir}" "${__deploy_dck_env_tags}"
    if ! [ "$?" -eq 1 ]; then
      echR "Invalid deployPrepareEnvFile"
      continue;
    else
      __dk_mcs_dk_env_file=${__func_return}
    fi
    #envsReplaceFile ${__dk_mcs_dk_yml}
    echG "  Finished"

    __dk_mcs_dep_dir="${STACK_APPLICATIONS_DATA_SRC_DIR}/${__dk_mcs_project} ${STACK_INSTALLER_DOCKER_CONF_DIR}/${APPLICATION_STACK}"

    if [[ ${__dk_mcs_git_branch} == "" ]]; then
      __dk_mcs_git_branch=master
    fi

    deploy \
          "${__dk_mcs_environment}" \
          "${__dk_mcs_target}" \
          "${__dk_mcs_project}" \
          "${__dk_mcs_builder_dir}" \
          "${__dk_mcs_build_option}" \
          "${__dk_mcs_git_repository}" \
          "${__dk_mcs_git_branch}" \
          "${__dk_mcs_dk_image}" \
          "${__dk_mcs_dk_file}" \
          "${__dk_mcs_dk_yml}" \
          "${__dk_mcs_dk_env_file}" \
          "${__dk_mcs_bin_dir}" \
          "${__dk_mcs_dep_dir}"
    if ! [ "$?" -eq 1 ]; then
      FAIL_DETECTED=true
      continue;
    fi
  done

  systemETCHostApply
  echG "  Finished"    
  if [[ ${FAIL_DETECTED} == true ]]; then
    echR "  =============================  "
    echR "  ********FAIL DETECTED********  "
    echR "  ********FAIL DETECTED********  "
    echR "  =============================  "    
    return 0;
  fi
  return 1;
}

function databaseUpdate()
{
  databaseUpdateExec
  return 0
}

function databaseDDLMaker()
{
  databaseDDLMakerExec
  return 0
}

function systemDNSOptions()
{
  opt=$(selectorDNSOption)
  if [[ ${opt} == "etc-hosts" ]]; then
   systemETCHostApply
  elif [[ ${opt} == "print" ]]; then
    systemETCHostPrint
  fi 
  return 1
}