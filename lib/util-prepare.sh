#!/bin/bash

. ${BASH_BIN}/bash-util.sh


function __privateEnvsPrepareClear()
{
  logStart ${1} "__privateEnvsPrepareClear"
  export APPLICATION_TEMPLATE=
  export APPLICATION_PROTOCOL=
  export APPLICATION_STACK=
  export APPLICATION_NAME=
  export APPLICATION_GIT=
  export APPLICATION_GIT_BRANCH=
  export APPLICATION_VERSION=
  export APPLICATION_AUTH=
  export APPLICATION_DEPLOY_CONTAINER_NAME=
  export APPLICATION_DEPLOY_PORT=
  export APPLICATION_DEPLOY_CONTEXT_PATH=
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
  export APPLICATION_DB_TYPE=
  export APPLICATION_DB_DRIVER=
  export APPLICATION_DB_HOST=
  export APPLICATION_DB_PORT=
  export APPLICATION_DB_USER=
  export APPLICATION_DB_PASSWORD=
  export APPLICATION_DB_SCHEMA=
  export APPLICATION_DB_DATABASE=
  export APPLICATION_ENV_FILE=
  export APPLICATION_ENV_FILES=
  logFinished ${1} "__privateEnvsPrepareClear"
}

function __privateEnvsPrepare()
{    
  logStart ${1} "__privateEnvsPrepare"
  export PUBLIC_APPLICATIONS_DIR=${HOME}/applications
  export PUBLIC_STORAGE_DIR=${PUBLIC_APPLICATIONS_DIR}/storage
  export PUBLIC_LIB_DIR=${PUBLIC_APPLICATIONS_DIR}/lib

  export STACK_DB_DROP=0
  export STACK_DOMAIN=portela-professional.com.br
  logFinished ${1} "__privateEnvsPrepare"
}

function __privateEnvsPublic()
{
  logStart ${1} "__privateEnvsPublic"
  export PUBLIC_ENVIRONMENT_FILE=${PUBLIC_APPLICATIONS_DIR}/${STACK_ENVIRONMENT}/stack_envs.env
  runSource ${1} ${PUBLIC_ENVIRONMENT_FILE} 
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi

  logFinished ${1} "__privateEnvsPublic"
  return 1
}

function __privateEnvsDefault()
{
  logStart ${1} "__privateEnvsDefault"
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
  logFinished ${1} "__privateEnvsDefault"
}

function __privateEnvsFinal()
{
  logStart ${1} "__privateEnvsDefault"
  export STACK_PREFIX=${STACK_ENVIRONMENT}-${STACK_TARGET}
  export STACK_NETWORK_INBOUND=${STACK_PREFIX}-inbound
  export STACK_REGISTRY_DNS=${STACK_PREFIX}-registry.${STACK_DOMAIN}:5000
  logFinished ${1} "__privateEnvsFinal"
}

function __privateEnvsDir()
{
  logStart ${1} "__privateEnvsDir"
  #APPLICATIONS DIR
  export STACK_APPLICATIONS_DIR=${ROOT_DIR}/applications
  export STACK_APPLICATIONS_PROJECT_DIR=${STACK_APPLICATIONS_DIR}/projects
  export STACK_APPLICATIONS_DATA_DIR=${STACK_APPLICATIONS_DIR}/data
  export STACK_APPLICATIONS_DATA_ENV_DIR=${STACK_APPLICATIONS_DATA_DIR}/envs
  export STACK_APPLICATIONS_DATA_CONF_DIR=${STACK_APPLICATIONS_DATA_DIR}/conf
  export STACK_APPLICATIONS_DATA_SRC_DIR=${STACK_APPLICATIONS_DATA_DIR}/source
  export STACK_APPLICATIONS_DATA_DB_DIR=${STACK_APPLICATIONS_DATA_DIR}/db


  #INSTALLER DIR
  export STACK_INSTALLER_DIR=${ROOT_DIR}/installer
  export STACK_INSTALLER_BIN_DIR=${STACK_INSTALLER_DIR}/bin
  export STACK_INSTALLER_BIN_DIR=${STACK_INSTALLER_DIR}/bin
  export STACK_INSTALLER_LIB_DIR=${STACK_INSTALLER_DIR}/lib
  export STACK_INSTALLER_DOCKER_DIR=${STACK_INSTALLER_DIR}/docker
  export STACK_INSTALLER_DOCKER_CONF_DIR=${STACK_INSTALLER_DOCKER_DIR}/conf
  export STACK_INSTALLER_DOCKER_FILE_DIR=${STACK_INSTALLER_DOCKER_DIR}/dockerfiles
  export STACK_INSTALLER_DOCKER_SSH_KEYS_DIR=${STACK_INSTALLER_DOCKER_DIR}/ssh-keys
  export STACK_INSTALLER_DOCKER_COMPOSE_DIR=${STACK_INSTALLER_DOCKER_DIR}/compose
  logFinished ${1} "__privateEnvsDir"
}


function utilPrepareClear()
{
  logStart ${1} "utilPrepareClear"
  __privateEnvsPrepareClear "$(incInt ${1})"  
  logFinished ${1} "utilPrepareClear"
}

function utilPrepareInit()
{
  logStart ${1} "utilPrepareInit"
  __privateEnvsPrepareClear "$(incInt ${1})"
  __privateEnvsPrepare "$(incInt ${1})"
  __privateEnvsPublic "$(incInt ${1})"
  if [ "$?" -eq 1 ]; then
    __privateEnvsDefault "$(incInt ${1})"
    __privateEnvsFinal "$(incInt ${1})"
    __privateEnvsDir "$(incInt ${1})"
    logFinished ${1} "utilPrepareInit"
    return 1
  fi
  logFinished ${1} "utilPrepareInit"
  return 0
}

function __utilPrepareStackEnvsDefault()
{
  logStart ${1} "__utilPrepareStackEnvsDefault"
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
  BUILD_DEPLOY_DNS=${BUILD_DEPLOY_APP_NAME}.${STACK_DOMAIN}
  BUILD_DEPLOY_NODE="node.role==manager"
  BUILD_DEPLOY_REPLICAS=${STACK_DEPLOY_REPLICAS}
  BUILD_DEPLOY_IMAGE_NAME=${BUILD_DEPLOY_APP_NAME}
  BUILD_DEPLOY_IMAGE_DNS=${STACK_REGISTRY_DNS}/${BUILD_DEPLOY_IMAGE_NAME}

  export BUILD_TEMP_DIR=${HOME}/build/${BUILD_DEPLOY_APP_NAME}
  export BUILD_TEMP_SOURCE_DIR=${BUILD_TEMP_DIR}/src
  export BUILD_TEMP_APP_DATA_DIR=${BUILD_TEMP_DIR}/app
  export BUILD_TEMP_APP_SOURCE_CONF_DIR=${STACK_APPLICATIONS_DATA_CONF_DIR}/${STACK_PROJECT}
  export BUILD_TEMP_APP_DATA_SOURCE_JAR=${BUILD_TEMP_DIR}/app/app.jar
  export BUILD_TEMP_APP_ENV_FILE=${BUILD_TEMP_DIR}/env_file.env
  export BUILD_TEMP_APP_BIN_SRC_DIR=${STACK_APPLICATIONS_DATA_SRC_DIR}/${STACK_PROJECT}
  
  
  makeDir "$(incInt ${1})" ${BUILD_TEMP_DIR} 777
  makeDir "$(incInt ${1})" ${BUILD_TEMP_APP_DATA_DIR} 777

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

  if [[ ${APPLICATION_DEPLOY_DNS} == "" ]]; then
    export APPLICATION_DEPLOY_DNS=${BUILD_DEPLOY_DNS}
  fi

  if [[ ${APPLICATION_DEPLOY_IMAGE} == "" ]]; then
    export APPLICATION_DEPLOY_IMAGE=${BUILD_DEPLOY_IMAGE_DNS}
  fi  

  if [[ ${APPLICATION_DEPLOY_ENV_FILE} == "" ]]; then
    export APPLICATION_DEPLOY_ENV_FILE=${BUILD_TEMP_APP_ENV_FILE}
  fi  

  if [[ ${APPLICATION_DEPLOY_CONTAINER_NAME} == "" ]]; then
    export APPLICATION_DEPLOY_CONTAINER_NAME=${BUILD_DEPLOY_CONTAINER_NAME}
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

  export APPLICATION_STORAGE_TARGET=${PUBLIC_STORAGE_DIR}/${STACK_PREFIX}
  makeDir "$(incInt ${1})" ${BUILD_TEMP_DIR} 777
  
  export BUILD_DEPLOY_DATA_DIR=${APPLICATION_STORAGE_TARGET}/${APPLICATION_NAME}
  export BUILD_DEPLOY_DATA_APP_DIR=${BUILD_DEPLOY_DATA_DIR}/data
  export BUILD_DEPLOY_DATA_BACKUP_DIR=${BUILD_DEPLOY_DATA_DIR}/backup
  
  if [[ ${APPLICATION_DEPLOY_DATA_DIR} == "" ]]; then
    export APPLICATION_DEPLOY_DATA_DIR=${BUILD_DEPLOY_DATA_APP_DIR}
  fi
  if [[ ${APPLICATION_DEPLOY_BACKUP_DIR} == "" ]]; then
    export APPLICATION_DEPLOY_BACKUP_DIR=${BUILD_DEPLOY_DATA_BACKUP_DIR}
  fi
  
  if [[ ${APPLICATION_DEPLOY_DATA_BK_DIR} == "" ]]; then
    export APPLICATION_DEPLOY_DATA_BK_DIR=${BUILD_DEPLOY_DATA_BK_DIR}
  fi

  makeDir "$(incInt ${1})" ${BUILD_TEMP_DIR} 777
  makeDir "$(incInt ${1})" ${APPLICATION_DEPLOY_DATA_DIR} 777
  makeDir "$(incInt ${1})" ${APPLICATION_DEPLOY_BACKUP_DIR} 777
  logFinished ${1} "__utilPrepareStackEnvsDefault"
}

function __utilPrepareStackEnvs()
{
  idt=$(incInt ${1})
  logStart ${1} "__utilPrepareStackEnvs"
  logTarget ${1} ${BUILD_TEMP_APP_ENV_FILE}

  echo "#!/bin/bash" > ${BUILD_TEMP_APP_ENV_FILE} 

  IMAGE_ENVS=${APPLICATION_STACK}.env

  #ENV_DIR_LIST=(${STACK_APPLICATIONS_DATA_ENV_DIR} ${STACK_INSTALLER_DOCKER_FILE_DIR})
  ENV_DIR_LIST=(${STACK_APPLICATIONS_DATA_ENV_DIR} ${STACK_INSTALLER_DOCKER_FILE_DIR})
  ENV_LIST=(default.env ${IMAGE_ENVS} ${APPLICATION_ENV_FILES} ${APPLICATION_ENV_FILES})

  for ENV_DIR in "${ENV_DIR_LIST[@]}"
  do
    for ENV_NAME in "${ENV_LIST[@]}"
    do
      ENV_FILE=${ENV_DIR}/${ENV_NAME}
      if ! [[ -f ${ENV_FILE} ]]; then
        logWarning ${1} "${ENV_FILE} not found"
        continue;
      fi  
      logTarget ${idt} "info: append ${ENV_FILE}"
      runSource ${idt} ${ENV_FILE} 
      if ! [ "$?" -eq 1 ]; then
        continue;
      else
        echo "" >> ${BUILD_TEMP_APP_ENV_FILE}
        cat ${ENV_FILE} >> ${BUILD_TEMP_APP_ENV_FILE}
        echo "" >> ${BUILD_TEMP_APP_ENV_FILE}
      fi      
    done
  done
  
  envsParserFile ${1} ${BUILD_TEMP_APP_ENV_FILE}
  runSource ${1} ${BUILD_TEMP_APP_ENV_FILE}
  envsToSimpleEnvs ${1} ${BUILD_TEMP_APP_ENV_FILE}
  logFinished ${1} "__utilPrepareStackEnvs"
}


function utilPrepareStack()
{
  logStart ${1} "utilPrepareStack"
  __utilPrepareStackEnvsDefault "$(incInt ${1})"
  __utilPrepareStackEnvs "$(incInt ${1})"
  logFinished ${1} "utilPrepareStack"
}
