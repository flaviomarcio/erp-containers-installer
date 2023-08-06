#!/bin/bash -e

. ${BASH_BIN}/lib-strings.sh

function __privateEnvsIsInited()
{
  if [[ ${STACK_ROOT_DIR} == "" ]]; then
    export STACK_ROOT_DIR=${HOME}
  fi
  export PUBLIC_APPLICATIONS_DIR=${STACK_ROOT_DIR}/applications
  export PUBLIC_STACK_TARGET_FILE=${STACK_ROOT_DIR}/applications/stack_targets.env
  export PUBLIC_ENVIRONMENT_FILE=${PUBLIC_APPLICATIONS_DIR}/${STACK_ENVIRONMENT}/${STACK_TARGET}/stack_envs.env
  export PUBLIC_ENVS_DIR=${PUBLIC_APPLICATIONS_DIR}/${STACK_ENVIRONMENT}/envs
  if ! [[ -f ${PUBLIC_STACK_TARGET_FILE} ]]; then
    echY "Environment no inited"
    echR "Invalid targets file: ${PUBLIC_STACK_TARGET_FILE}"
  elif ! [[ -f ${PUBLIC_ENVIRONMENT_FILE} ]]; then
    echY "Environment no inited"
    echR "Invalid stack env file: ${PUBLIC_ENVIRONMENT_FILE}"
  else
    source ${PUBLIC_ENVIRONMENT_FILE}
    return 1
  fi
  return 0
}

function __privateEnvsPrepareClear()
{
  export APPLICATION_STACK=
  export APPLICATION_NAME=
  export APPLICATION_GIT=
  export APPLICATION_GIT_BRANCH=
  export APPLICATION_DEPLOY_PORT=
  export APPLICATION_DEPLOY_DNS=
  export APPLICATION_DEPLOY_DNS_PUBLIC=
  export APPLICATION_DEPLOY_IMAGE=
  export APPLICATION_DEPLOY_HOSTNAME=
  export APPLICATION_DEPLOY_NODE=
  export APPLICATION_DEPLOY_MODE=
  export APPLICATION_DEPLOY_REPLICAS=
  export APPLICATION_DEPLOY_DATA_DIR=
  export APPLICATION_DEPLOY_BACKUP_DIR=
  export APPLICATION_DEPLOY_NETWORK_NAME=
  return 1
}



function __privateEnvsPrepare()
{    
  export PUBLIC_STORAGE_DIR=$(realpath ${PUBLIC_APPLICATIONS_DIR}/storage)
  export PUBLIC_LIB_DIR=$(realpath ${PUBLIC_APPLICATIONS_DIR}/lib)
  export STACK_DB_DROP=0
  export STACK_DOMAIN=local
  return 1
}

function __privateEnvsPublic()
{
  if ! [[ -f ${PUBLIC_STACK_TARGET_FILE} ]]; then
    echY "Environment no inited"
    echR "Invalid targets file: ${PUBLIC_STACK_TARGET_FILE}"
  elif ! [[ -f ${PUBLIC_ENVIRONMENT_FILE} ]]; then
    echY "Environment no inited"
    echR "Invalid enviroment file: ${PUBLIC_ENVIRONMENT_FILE}"
  else
    source ${PUBLIC_ENVIRONMENT_FILE}
    return 1
  fi
  return 0
}

function __privateEnvsDefault()
{
  if [[ ${STACK_CPU_DEFAULT} == "" ]]; then
      export STACK_CPU_DEFAULT=1
  fi
  if [[ ${STACK_MEMORY_DEFAULT} == "" ]]; then
      export STACK_MEMORY_DEFAULT=1GB
  fi
  if [[ ${STACK_DEPLOY_REPLICAS} == "" ]]; then
      export STACK_DEPLOY_REPLICAS=1
  fi
  if [[ ${STACK_DOMAIN} == "" ]]; then
      export STACK_DNS=localhost
  fi
  return 1
}

function __privateEnvsFinal()
{
  export STACK_NETWORK_INBOUND=${STACK_PREFIX}-inbound
  export STACK_REGISTRY_DNS=${STACK_PREFIX}-registry:5000
  export STACK_REGISTRY_DNS_PUBLIC=${STACK_PREFIX}-registry.${STACK_DOMAIN}:5000
  return 1
}

function __privateEnvsDir()
{
  #APPLICATIONS DIR
  export STACK_APPLICATIONS_DIR=${ROOT_DIR}/applications
  export STACK_APPLICATIONS_PROJECT_DIR=${STACK_APPLICATIONS_DIR}/projects
  export STACK_APPLICATIONS_DATA_DIR=${STACK_APPLICATIONS_DIR}/data
  export STACK_APPLICATIONS_DATA_ENV_DIR=${STACK_APPLICATIONS_DATA_DIR}/envs
  export STACK_APPLICATIONS_DATA_ENV_JSON_FILE=${STACK_APPLICATIONS_DATA_ENV_DIR}/env_file_default.json
  export STACK_APPLICATIONS_DATA_CONF_DIR=${STACK_APPLICATIONS_DATA_DIR}/conf
  export STACK_APPLICATIONS_DATA_SRC_DIR=${STACK_APPLICATIONS_DATA_DIR}/source
  export STACK_APPLICATIONS_DATA_DB_DIR=${STACK_APPLICATIONS_DATA_DIR}/db

  #INSTALLER DIR
  export STACK_INSTALLER_BIN_DIR=${INSTALLER_DIR}/bin
  export STACK_INSTALLER_LIB_DIR=${INSTALLER_DIR}/lib
  export STACK_INSTALLER_DOCKER_DIR=${INSTALLER_DIR}/docker
  export STACK_INSTALLER_DOCKER_CONF_DIR=${STACK_INSTALLER_DOCKER_DIR}/conf
  export STACK_INSTALLER_DOCKER_FILE_DIR=${STACK_INSTALLER_DOCKER_DIR}/dockerfiles
  export STACK_INSTALLER_DOCKER_COMPOSE_DIR=${STACK_INSTALLER_DOCKER_DIR}/compose
  return 1
}

function utilPrepareClear()
{
  __privateEnvsPrepareClear
}

function utilPrepareInit()
{
  __privateEnvsIsInited
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  __privateEnvsPrepareClear
  if ! [ "$?" -eq 1 ]; then
    echR
    return 0
  fi
  __privateEnvsPrepare
  if ! [ "$?" -eq 1 ]; then
    echR
    return 0
  fi
  __privateEnvsPublic
  if ! [ "$?" -eq 1 ]; then
    echR
    return 0
  fi
  __privateEnvsDefault
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  __privateEnvsFinal
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  __privateEnvsDir
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  return 1
}

function prepareStackForDeploy()
{
  __prepareStack_prefix_name=${STACK_PREFIX}-${STACK_PROJECT}
  if [[ ${APPLICATION_NAME} == "" ]]; then
    export APPLICATION_NAME=${STACK_PROJECT}
  fi 
  if [[ ${APPLICATION_DEPLOY_PORT} == "" ]]; then
    export APPLICATION_DEPLOY_PORT=8080
  fi
  if [[ ${APPLICATION_DEPLOY_DNS} == "" ]]; then
    export APPLICATION_DEPLOY_DNS=${__prepareStack_prefix_name}
  fi
  if [[ ${APPLICATION_DEPLOY_DNS_PUBLIC} == "" ]]; then
    export APPLICATION_DEPLOY_DNS_PUBLIC=${__prepareStack_prefix_name}.${STACK_DOMAIN}
  fi
  if [[ ${APPLICATION_DEPLOY_IMAGE} == "" ]]; then
    export APPLICATION_DEPLOY_IMAGE=${STACK_REGISTRY_DNS_PUBLIC}/${__prepareStack_prefix_name}  
  fi
  if [[ ${APPLICATION_DEPLOY_HOSTNAME} == "" ]]; then
    export APPLICATION_DEPLOY_HOSTNAME=${__prepareStack_prefix_name}
  fi
  if [[ ${APPLICATION_DEPLOY_MODE} == "" ]]; then
    export APPLICATION_DEPLOY_MODE=replicated
  fi  
  if [[ ${APPLICATION_DEPLOY_NODE} == "" ]]; then
    export APPLICATION_DEPLOY_NODE=${STACK_SERVICE_NODE_SERVICES}
  fi
  if [[ ${APPLICATION_DEPLOY_REPLICAS} == "" ]]; then
    export APPLICATION_DEPLOY_REPLICAS=1
  fi
  if [[ ${APPLICATION_DEPLOY_NETWORK_NAME} == "" ]]; then
    export APPLICATION_DEPLOY_NETWORK_NAME=${STACK_NETWORK_INBOUND}
  fi
  if [[ ${APPLICATION_DEPLOY_DATA_DIR} == "" ]]; then
    export APPLICATION_DEPLOY_DATA_DIR=${PUBLIC_STORAGE_DIR}/${STACK_PREFIX}/${__dk_mcs_project}/data
  fi
  if [[ ${APPLICATION_DEPLOY_BACKUP_DIR} == "" ]]; then
    export APPLICATION_DEPLOY_BACKUP_DIR=${PUBLIC_STORAGE_DIR}/${STACK_PREFIX}/${__dk_mcs_project}/backup
  fi
  if ! [[ -d ${APPLICATION_DEPLOY_DATA_DIR} ]]; then
    mkdir -p ${APPLICATION_DEPLOY_DATA_DIR}
    chmod 777 ${APPLICATION_DEPLOY_DATA_DIR}
  fi
  if ! [[ -d ${APPLICATION_DEPLOY_BACKUP_DIR} ]]; then
    mkdir -p ${APPLICATION_DEPLOY_BACKUP_DIR}
    chmod 777 ${APPLICATION_DEPLOY_BACKUP_DIR}
  fi

}
