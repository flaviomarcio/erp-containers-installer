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

  export STACK_TARGET=${__dk_mcs_target}

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
  
  utilPrepareInit 1
  for __dk_mcs_project in "${__dk_mcs_projects[@]}"
  do
    export STACK_PROJECT=${__dk_mcs_project}

    runSource 1 "${__dk_mcs_project_dir}/${__dk_mcs_project}"
    if ! [ "$?" -eq 1 ]; then
      exit 0;
    fi
    buildProjectPrepare 1 ${STACK_PROJECT} ${STACK_PROJECT}

    __dk_mcs_builder_dir=${HOME}/build
    __dk_mcs_git_repository=${APPLICATION_GIT}
    __dk_mcs_git_branch=${APPLICATION_GIT_BRANCH}
    __dk_mcs_dk_yml=${STACK_INSTALLER_DOCKER_COMPOSE_DIR}/${APPLICATION_STACK}.yml
    __dk_mcs_dk_file=${STACK_INSTALLER_DOCKER_FILE_DIR}/${APPLICATION_STACK}.dockerfile
    __dk_mcs_dk_image=${APPLICATION_DEPLOY_IMAGE}
    
    __dk_mcs_dk_env=$(echo ${__dk_mcs_dk_yml} | sed 's/yml/env/g')
    cp -rf ${APPLICATION_DEPLOY_ENV_FILE} ${__dk_mcs_dk_env}

    __dk_mcs_bin_dir=${HOME}/build/bin
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
          "${__dk_mcs_dk_env}" \
          "${__dk_mcs_bin_dir}" \
          "${__dk_mcs_dep_dir}"

  done

  return 1
  export STACK_TYPE=mcs
  while :
  do
    export FAIL_DETECTED=
    clearTerm
    echG "Git repository list"
    export REPOSITORY_LIST=$(selectorRepository)
    if [[ ${REPOSITORY_LIST} == "" ]]; then
      continue
    elif [[ ${REPOSITORY_LIST} == "Tag" ]]; then
      clearTerm
      echG "Git repository tags"
      export REPOSITORY_LIST=$(selectorRepositoryTags)
      if [[ ${REPOSITORY_LIST} == "" ]]; then
        continue
      fi
    fi
    export REPOSITORY_LIST=(${REPOSITORY_LIST})

    clearTerm
    echG "Build/deploy options for:"
    for STACK_NAME in "${REPOSITORY_LIST[@]}"
    do
    echC "  - ${STACK_NAME}"
    done
    echC
    export BUILD_OPTION=$(selectorBuildOption)
    if [[ ${BUILD_OPTION} == "" ]]; then
      continue
    fi  

    clearTerm
    echG "Deploying micro services"
    echC "  - Build option: [${BUILD_OPTION}]"
    echC
    if [[ ${BUILD_OPTION} != "deploy" ]]; then
      for STACK_NAME in "${REPOSITORY_LIST[@]}"
      do
        mavenBuild ${STACK_TYPE} ${STACK_NAME}
        if ! [ "$?" -eq 1 ]; then
          FAIL_DETECTED=true
          continue;
        fi
      done
    fi

    if [[ ${BUILD_OPTION} == "build-and-deploy" || ${BUILD_OPTION} == "deploy" ]]; then
      for STACK_NAME in "${REPOSITORY_LIST[@]}"
      do
        mavenPrepare ${STACK_TYPE} ${STACK_NAME}
        dockerBuild ${STACK_TYPE} ${STACK_NAME}
        if ! [ "$?" -eq 1 ]; then
          FAIL_DETECTED=true
          continue;
        fi
      done
    fi
    systemETCHostApply
    echG "  Finished"    
    if [[ ${FAIL_DETECTED} == true ]]; then
      echR "  =============================  "
      echR "  ********FAIL DETECTED********  "
      echR "  ********FAIL DETECTED********  "
      echR "  =============================  "    
    fi
    break
  done
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