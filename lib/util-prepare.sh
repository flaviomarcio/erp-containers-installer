#!/bin/bash

. ${INSTALLER_DIR}/lib/util.sh

function __privateEnvsPrepare()
{    
  export PUBLIC_APPLICATIONS_DIR=${HOME}/applications
  export PUBLIC_STORAGE_DIR=${PUBLIC_APPLICATIONS_DIR}/storage
  export PUBLIC_LIB_DIR=${PUBLIC_APPLICATIONS_DIR}/lib
  export PUBLIC_ENVIRONMENT_FILE=${PUBLIC_APPLICATIONS_DIR}/stack_envs

  export STACK_DB_DROP=0
  export STACK_DOMAIN=portela-professional.com.br
}

function __privateEnvsPublic()
{
  if ! [[ -f ${PUBLIC_ENVIRONMENT_FILE} ]]; then
    log "Invalid public env: ${PUBLIC_ENVIRONMENT_FILE}"
  else
    runSource ${PUBLIC_ENVIRONMENT_FILE}
  fi
}

function __privateEnvsDefault()
{
  if [[ ${QT_VERSION} == "" ]]; then
      export QT_VERSION=6.4.2
  fi
  if [[ ${STACK_CPU_DEFAULT} == "" ]]; then
      export STACK_CPU_DEFAULT=1
  fi
  if [[ ${STACK_MEMORY_DEFAULT} == "" ]]; then
      export STACK_MEMORY_DEFAULT=1GB
  fi
  if [[ ${STACK_DEPLOY_REPLICAS} == "" ]]; then
      export STACK_DEPLOY_REPLICAS=1
  fi
  if [[ ${STACK_ENVIRONMENT} == "" ]]; then
      export STACK_ENVIRONMENT=testing
  fi
  if [[ ${STACK_DOMAIN} == "" ]]; then
      export STACK_DNS=localhost
  fi
  if [[ ${STACK_TARGET} == "" ]]; then
      export STACK_TARGET=company
  fi
}

function __privateEnvsFinal()
{
  export STACK_PREFIX=${STACK_ENVIRONMENT}-${STACK_TARGET}
  export STACK_NETWORK_INBOUND=${STACK_PREFIX}-inbound
  export STACK_REGISTRY_DNS=${STACK_PREFIX}-registry.${STACK_DOMAIN}:5000
}

function __privateEnvsDir()
{
  #APPLICATIONS DIR
  export STACK_APPLICATIONS_DIR=${ROOT_DIR}/applications
  export STACK_APPLICATIONS_PROJECT_DIR=${STACK_APPLICATIONS_DIR}/projects
  export STACK_APPLICATIONS_DB_DIR=${STACK_APPLICATIONS_DIR}/db  
  export STACK_APPLICATIONS_DATA_DIR=${STACK_APPLICATIONS_DIR}/data
  export STACK_APPLICATIONS_ENV_DIR=${STACK_APPLICATIONS_DATA_DIR}/envs
  export STACK_APPLICATIONS_CONFIG_DIR=${STACK_APPLICATIONS_DATA_DIR}/conf
  export STACK_APPLICATIONS_SOURCE_DIR=${STACK_APPLICATIONS_DATA_DIR}/source

  #INSTALLER DIR
  export STACK_INSTALLER_BIN_DIR=${INSTALLER_DIR}/bin
  export STACK_INSTALLER_LIB_DIR=${INSTALLER_DIR}/lib
  export STACK_INSTALLER_DOCKER_DIR=${INSTALLER_DIR}/docker
  export STACK_INSTALLER_DOCKER_FILE_DIR=${STACK_INSTALLER_DOCKER_DIR}/dockerfiles
  export STACK_INSTALLER_DOCKER_COMPOSE_DIR=${STACK_INSTALLER_DOCKER_DIR}/compose
}


function utilPrepareInit()
{
  __privateEnvsPrepare
  __privateEnvsPublic
  __privateEnvsDefault
  __privateEnvsFinal
  __privateEnvsDir
}

function __privateBuildDefault()
{
  if [[ ${APPLICATION_NAME} == "" ]]; then
    export APPLICATION_NAME=${STACK_PROJECT}
  fi

  export BUILD_DEPLOY_APP_NAME=${STACK_PREFIX}-${APPLICATION_NAME}
  export BUILD_DEPLOY_MODE=replicated
  export BUILD_DEPLOY_CONTEXT_PATH=/
  export BUILD_DEPLOY_PORT=8080
  export BUILD_DEPLOY_CONTAINER_NAME=${BUILD_DEPLOY_APP_NAME}
  export BUILD_DEPLOY_DNS=${BUILD_DEPLOY_APP_NAME}.${STACK_DOMAIN}
  export BUILD_DEPLOY_NODE="node.role==manager"
  export BUILD_DEPLOY_IMAGE_NAME=${BUILD_DEPLOY_APP_NAME}
  export BUILD_DEPLOY_IMAGE_DNS=${STACK_REGISTRY_DNS}/${BUILD_DEPLOY_IMAGE_NAME}

  export BUILD_TEMP_DIR=${HOME}/build/${BUILD_DEPLOY_APP_NAME}
  export BUILD_TEMP_SOURCE_DIR=${BUILD_TEMP_DIR}/src
  export BUILD_TEMP_APP_DIR=${BUILD_TEMP_DIR}/app
  export BUILD_TEMP_APP_JAR=${BUILD_TEMP_DIR}/app/app.jar
  export BUILD_TEMP_APP_ENV_FILE=${BUILD_TEMP_DIR}/env_file.env
  export BUILD_TEMP_APP_BIN_SRC_DIR=${STACK_APPLICATIONS_SOURCE_DIR}/${BUILD_DEPLOY_CONTAINER_NAME}

  export DOCKER_FILE_NAME=${APPLICATION_STACK}.dockerfile
  export DOCKER_STACK_FILE_NAME=${APPLICATION_STACK}.yml
  
  if [[ ${APPLICATION_DEPLOY_PORT} == "" ]]; then
    export APPLICATION_DEPLOY_PORT=${BUILD_DEPLOY_PORT}
  fi

  if [[ ${APPLICATION_DEPLOY_CONTEXT_PATH} == "" ]]; then
    export APPLICATION_DEPLOY_CONTEXT_PATH=${BUILD_DEPLOY_CONTEXT_PATH}
  fi

  if [[ ${APPLICATION_DEPLOY_DNS} == "" ]]; then
    export APPLICATION_DEPLOY_DNS=${BUILD_DEPLOY_DNS}
  fi

  if [[ ${APPLICATION_DEPLOY_IMAGE} == "" ]]; then
    export APPLICATION_DEPLOY_IMAGE=${BUILD_DEPLOY_IMAGE_DNS}
  fi  

  if [[ ${APPLICATION_DEPLOY_IMAGE} == "" ]]; then
    export APPLICATION_DEPLOY_IMAGE=${BUILD_TEMP_APP_ENV_FILE}
  fi  

  if [[ ${APPLICATION_DEPLOY_HOSTNAME} == "" ]]; then
    export APPLICATION_DEPLOY_HOSTNAME=${BUILD_DEPLOY_CONTAINER_NAME}
  fi
 
  if [[ ${APPLICATION_DEPLOY_MODE} == "" ]]; then
    export APPLICATION_DEPLOY_MODE=${STACK_DEPLOY_MODE}
  fi
  
  if [[ ${APPLICATION_DEPLOY_NODE} == "" ]]; then
    export APPLICATION_DEPLOY_NODE=${BUILD_DEPLOY_NODE}
  fi

  if [[ ${APPLICATION_DEPLOY_REPLICAS} == "" ]]; then
    export APPLICATION_DEPLOY_REPLICAS=${STACK_DEPLOY_REPLICAS}
  fi
  if [[ ${APPLICATION_DEPLOY_NETWORK_NAME} == "" ]]; then
    export APPLICATION_DEPLOY_NETWORK_NAME=${STACK_NETWORK_INBOUND}
  fi  

  export BUILD_DEPLOY_DATA_DIR=${STACK_APPLICATIONS_SOURCE_DIR}/${BUILD_DEPLOY_CONTAINER_NAME}
  export BUILD_DEPLOY_DATA_INFO_DIR=${BUILD_DEPLOY_DATA_DIR}-info
  export BUILD_DEPLOY_DATA_BACKUP_DIR=${BUILD_DEPLOY_DATA_DIR}-backup
  if [[ ${APPLICATION_DEPLOY_DATA_DIR} == "" ]]; then
    export APPLICATION_DEPLOY_DATA_DIR=${BUILD_DEPLOY_DATA_INFO_DIR}
    export APPLICATION_DEPLOY_BACKUP_DIR=${BUILD_DEPLOY_DATA_BACKUP_DIR}
  fi
  
  if [[ ${APPLICATION_DEPLOY_DATA_BK_DIR} == "" ]]; then
    export APPLICATION_DEPLOY_DATA_BK_DIR=${BUILD_DEPLOY_DATA_BK_DIR}
  fi

  makeDir ${BUILD_TEMP_DIR}
  makeDir ${APPLICATION_DEPLOY_DATA_DIR} 777
  makeDir ${APPLICATION_DEPLOY_BACKUP_DIR} 777
}

function __privateBuildEnvs()
{
  ENV_LIST=(default.env ${APPLICATION_ENV_FILES})
  for ENV_NAME in "${ENV_LIST[@]}"
  do
    ENV_FILE=${STACK_APPLICATIONS_ENV_DIR}/${ENV_NAME}
    if ! [[ -f ${ENV_FILE} ]]; then
      log -lvs "runSource ${ENV_FILE} not found"
      continue;
    fi  
    runSource ${ENV_FILE}
  done

  echo "#join envs: ${APPLICATION_EXPORT_ENVS}" > ${BUILD_TEMP_APP_ENV_FILE}
  ENV_LIST=(${APPLICATION_EXPORT_ENVS})
  for ENV_NAME in "${ENV_LIST[@]}"
  do
    env | grep "^${ENV_NAME}">>${BUILD_TEMP_APP_ENV_FILE}
  done
}

function utilPrepareStack()
{
    __privateBuildDefault
    __privateBuildEnvs
}
