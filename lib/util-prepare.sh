#!/bin/bash -e

. ${BASH_BIN}/bash-util.sh

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
    echR "Invalid file: ${PUBLIC_STACK_TARGET_FILE}"
  elif ! [[ -f ${PUBLIC_ENVIRONMENT_FILE} ]]; then
    echY "Environment no inited"
    echR "Invalid file: ${PUBLIC_ENVIRONMENT_FILE}"
  else
    source ${PUBLIC_ENVIRONMENT_FILE}
    return 1
  fi
  return 0
}

function __privateEnvsPrepareClear()
{
  export APPLICATION_TEMPLATE=
  export APPLICATION_PROTOCOL=
  export APPLICATION_STACK=
  export APPLICATION_NAME=
  export APPLICATION_GIT=
  export APPLICATION_GIT_BRANCH=
  export APPLICATION_VERSION=
  export APPLICATION_AUTH=
  export APPLICATION_DEPLOY_PORT=
  export APPLICATION_DEPLOY_CONTEXT_PATH=
  export APPLICATION_DEPLOY_DNS_PUBLIC=
  export APPLICATION_DEPLOY_DNS=
  export APPLICATION_DEPLOY_IMAGE=
  export APPLICATION_DEPLOY_HOSTNAME=
  export APPLICATION_DEPLOY_NODE=
  export APPLICATION_DEPLOY_MODE=
  export APPLICATION_DEPLOY_REPLICAS=
  export APPLICATION_DEPLOY_NETWORK=
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
    echR "Invalid file: ${PUBLIC_STACK_TARGET_FILE}"
  elif ! [[ -f ${PUBLIC_ENVIRONMENT_FILE} ]]; then
    echY "Environment no inited"
    echR "Invalid file: ${PUBLIC_ENVIRONMENT_FILE}"
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
  export STACK_INSTALLER_DIR=${ROOT_DIR}/installer
  export STACK_INSTALLER_BIN_DIR=${INSTALLER_DIR}/bin
  export STACK_INSTALLER_LIB_DIR=${INSTALLER_DIR}/lib
  export STACK_INSTALLER_DOCKER_DIR=${INSTALLER_DIR}/docker
  export STACK_INSTALLER_DOCKER_CONF_DIR=${STACK_INSTALLER_DOCKER_DIR}/conf
  export STACK_INSTALLER_DOCKER_FILE_DIR=${STACK_INSTALLER_DOCKER_DIR}/dockerfiles
  export STACK_INSTALLER_DOCKER_SSH_KEYS_DIR=${STACK_INSTALLER_DOCKER_DIR}/ssh-keys
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

function prepareStack()
{
  if [[ ${APPLICATION_NAME} == "" ]]; then
    export APPLICATION_NAME=${STACK_PROJECT}
  fi

  BUILD_DEPLOY_APP_NAME=${STACK_PREFIX}-${APPLICATION_NAME}
  BUILD_DEPLOY_TEMPLATE=app
  BUILD_DEPLOY_PROTOCOL=http
  BUILD_DEPLOY_MODE=replicated
  BUILD_DEPLOY_CONTEXT_PATH=/
  BUILD_DEPLOY_PORT=8080
  BUILD_DEPLOY_CONTAINER_NAME=${BUILD_DEPLOY_APP_NAME}
  BUILD_DEPLOY_DNS_PRIVATE=${BUILD_DEPLOY_APP_NAME}
  BUILD_DEPLOY_DNS_PUBLIC=${BUILD_DEPLOY_DNS_PRIVATE}.${STACK_DOMAIN}
  BUILD_DEPLOY_NODE=${STACK_DEPLOY_NODE_ROLE}
  BUILD_DEPLOY_REPLICAS=${STACK_DEPLOY_REPLICAS}
  BUILD_DEPLOY_IMAGE_NAME=${BUILD_DEPLOY_APP_NAME}
  BUILD_DEPLOY_IMAGE_DNS=${STACK_REGISTRY_DNS_PUBLIC}/${BUILD_DEPLOY_IMAGE_NAME}

  export BUILD_TEMP_DIR=${HOME}/build/${BUILD_DEPLOY_APP_NAME}
  export BUILD_TEMP_SOURCE_DIR=${BUILD_TEMP_DIR}/src
  export BUILD_TEMP_APP_DATA_DIR=${BUILD_TEMP_DIR}/app
  export BUILD_TEMP_APP_ENV_FILE=${BUILD_TEMP_DIR}/env_file.env
  export BUILD_TEMP_APP_BIN_SRC_DIR=${STACK_APPLICATIONS_DATA_SRC_DIR}/${STACK_PROJECT}
  

  export DOCKER_CONF_DIR=${STACK_INSTALLER_DOCKER_CONF_DIR}/${APPLICATION_STACK}
  export DOCKER_FILE_NAME=${APPLICATION_STACK}.dockerfile
  export DOCKER_STACK_FILE_NAME=${APPLICATION_STACK}.yml
  export DOCKER_FILE_SRC=${STACK_INSTALLER_DOCKER_FILE_DIR}/${DOCKER_FILE_NAME}
  export DOCKER_FILE_DST=${BUILD_TEMP_DIR}/Dockerfile
  
  export APPLICATION_DEPLOY_APP_DIR=${BUILD_TEMP_APP_DATA_DIR}
  export APPLICATION_DEPLOY_BASHRC_FILE=${APPLICATION_DEPLOY_APP_DIR}/bashrc.sh
  
  if [[ ${APPLICATION_DEPLOY_PORT} == "" ]]; then
    export APPLICATION_DEPLOY_PORT=${BUILD_DEPLOY_PORT}
  fi

  if [[ ${APPLICATION_DEPLOY_CONTEXT_PATH} == "" ]]; then
    export APPLICATION_DEPLOY_CONTEXT_PATH=${BUILD_DEPLOY_CONTEXT_PATH}
  fi

  if [[ ${APPLICATION_DEPLOY_DNS_PUBLIC} == "" ]]; then
    export APPLICATION_DEPLOY_DNS_PUBLIC=false
  fi  

  if [[ ${APPLICATION_DEPLOY_DNS} == "" ]]; then
    if [[ ${APPLICATION_DEPLOY_DNS_PUBLIC} == "true" ]]; then
      export APPLICATION_DEPLOY_DNS=${BUILD_DEPLOY_DNS_PUBLIC}
    else
      export APPLICATION_DEPLOY_DNS=${BUILD_DEPLOY_DNS_PRIVATE}
    fi
  fi

  if [[ ${APPLICATION_DEPLOY_IMAGE} == "" ]]; then
    export APPLICATION_DEPLOY_IMAGE=${BUILD_DEPLOY_IMAGE_DNS}
  fi  

  if [[ ${APPLICATION_DEPLOY_HOSTNAME} == "" ]]; then
    export APPLICATION_DEPLOY_HOSTNAME=${BUILD_DEPLOY_CONTAINER_NAME}
  fi

  if [[ ${APPLICATION_DEPLOY_MODE} == "" ]]; then
    export APPLICATION_DEPLOY_MODE=${BUILD_DEPLOY_MODE}
  fi
  
  if [[ ${APPLICATION_DEPLOY_NODE} == "" ]]; then
    export APPLICATION_DEPLOY_NODE=${BUILD_DEPLOY_NODE}
  fi

  if [[ ${APPLICATION_DEPLOY_REPLICAS} == "" ]]; then
    export APPLICATION_DEPLOY_REPLICAS=${BUILD_DEPLOY_REPLICAS}
  fi

  if [[ ${APPLICATION_DEPLOY_NETWORK_NAME} == "" ]]; then
    export APPLICATION_DEPLOY_NETWORK_NAME=${STACK_NETWORK_INBOUND}
  fi  

  if [[ ${APPLICATION_TEMPLATE} == "" ]]; then
    export APPLICATION_TEMPLATE=${BUILD_DEPLOY_TEMPLATE}
  fi

  if [[ ${APPLICATION_PROTOCOL} == "" ]]; then
    export APPLICATION_PROTOCOL=${BUILD_DEPLOY_PROTOCOL}
  fi

  mkdir -p ${BUILD_TEMP_DIR}

}
