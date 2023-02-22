#!/bin/bash

. ${INSTALLER_DIR}/lib/util.sh
. ${INSTALLER_DIR}/lib/util-build.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh


function deployImage()
{
  logStart 1 "deployImage"
  logMethod ${1} "action: ${STACK_ACTION}"
  logMethod  1 "project: ${STACK_PROJECT}"
  if [[ ${1} != "" && ${2} != "" ]]; then
    export STACK_ACTION=${1}
    export STACK_PROJECT=${2}
  fi
  utilPrepareStack
  RUN_FILE="${STACK_INSTALLER_BIN_DIR}/prepare-${APPLICATION_STACK}.env"

  runSource 1 ${RUN_FILE} 

  buildProjectPrepare ${STACK_ACTION} ${STACK_PROJECT}
  buildRegistryImage

  rm -rf ${BUILD_TEMP_DIR}
  makeDir 2 ${BUILD_TEMP_DIR} 777
  makeDir 2 ${BUILD_TEMP_APP_DIR} 777
  
  export APPLICATION_FILTER=app*.jar
  export DOCKER_FILE_SRC=${STACK_INSTALLER_DOCKER_FILE_DIR}/${DOCKER_FILE_NAME}
  export DOCKER_FILE_DST=${BUILD_TEMP_DIR}/Dockerfile

  logFinished 1 "deployImage"
  return 1
}


function deployApp()
{
  logStart 1 "deployApp"
  if [[ ${1} != "" && ${2} != "" ]]; then
    export STACK_ACTION=${1}
    export STACK_PROJECT=${2}
  fi
  logInfo 1 "action" ${STACK_ACTION}
  logInfo 1 "project" ${STACK_PROJECT}

  utilPrepareStack

  cdDir 2 ${BUILD_TEMP_DIR};
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  logInfo 2 "build-dir" ${PWD}

  echo $'\n'"Deploying stack:[${STACK_PROJECT}], image:[${BUILD_DEPLOY_IMAGE_NAME}]"
  echo "  DNS Service: ${APPLICATION_DEPLOY_HOSTNAME}"

  CHECK=$(docker stack ls | grep ${APPLICATION_CONTAINER_NAME})
  if [[ ${CHECK} != "" ]]; then
    if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
      logCommand 1 "docker stack rm ${APPLICATION_CONTAINER_NAME}"
      docker stack rm ${APPLICATION_CONTAINER_NAME}
    else
      echo $(docker stack rm ${APPLICATION_CONTAINER_NAME})&>/dev/null
    fi    
  fi

  COMPOSE_SRC=${STACK_INSTALLER_DOCKER_COMPOSE_DIR}/${DOCKER_STACK_FILE_NAME}
  COMPOSE_DST=${PWD}/docker-compose.yml
  logInfo 1 "source" ${COMPOSE_SRC}
  logInfo 1 "destine" ${COMPOSE_DST}

  rm -rf ${COMPOSE_DST}
  cp -r ${COMPOSE_SRC} ${COMPOSE_DST}

  # echo "APPLICATION_DEPLOY_NETWORK_NAME=${APPLICATION_DEPLOY_NETWORK_NAME}"
  # echo "APPLICATION_DEPLOY_IMAGE=${APPLICATION_DEPLOY_IMAGE}"
  # echo "APPLICATION_DEPLOY_HOSTNAME=${APPLICATION_DEPLOY_HOSTNAME}"
  # echo "APPLICATION_DEPLOY_ENV_FILE=${APPLICATION_DEPLOY_ENV_FILE}"
  # echo "APPLICATION_DEPLOY_CONTEXT_PATH=${APPLICATION_DEPLOY_CONTEXT_PATH}"
  # echo "APPLICATION_DEPLOY_PORT=${APPLICATION_DEPLOY_PORT}"
  # echo "APPLICATION_DEPLOY_DATA_DIR=${APPLICATION_DEPLOY_DATA_DIR}"
  # echo "APPLICATION_DEPLOY_BACKUP_DIR=${APPLICATION_DEPLOY_BACKUP_DIR}"
  # echo "APPLICATION_DEPLOY_PORT=${APPLICATION_DEPLOY_PORT}"
  # echo "APPLICATION_DEPLOY_MODE=${APPLICATION_DEPLOY_MODE}"
  # echo "APPLICATION_DEPLOY_REPLICAS=${APPLICATION_DEPLOY_REPLICAS}"
  # echo "APPLICATION_DEPLOY_NODE=${APPLICATION_DEPLOY_NODE}"
  # echo "APPLICATION_NAME=${APPLICATION_NAME}"
  # echo "APPLICATION_DEPLOY_DNS=${APPLICATION_DEPLOY_DNS}"
  # echo "APPLICATION_DEPLOY_PORT=${APPLICATION_DEPLOY_PORT}"
  # echo "APPLICATION_DEPLOY_NETWORK_NAME=${APPLICATION_DEPLOY_NETWORK_NAME}"

  logCommand ${1} "docker stack deploy -c ${COMPOSE_DST} ${APPLICATION_CONTAINER_NAME}"
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    docker stack deploy -c ${COMPOSE_DST} ${APPLICATION_CONTAINER_NAME}
  else
    echo $(docker stack deploy -c ${COMPOSE_DST} ${APPLICATION_CONTAINER_NAME})&>/dev/null
  fi
  logFinished 1 "deployApp"
}

function deployImageApp()
{
  logStart 1 "deployImageApp"
  if [[ ${1} != "" && ${2} != "" ]]; then
    export STACK_ACTION=${1}
    export STACK_PROJECT=${2}
  fi
  logMethod ${1} "action: ${STACK_ACTION}"
  logMethod ${1} "project: ${STACK_PROJECT}"
  buildProjectPrepare ${STACK_ACTION} ${STACK_PROJECT}
  deployApp ${STACK_ACTION} ${STACK_PROJECT}
  logFinished 1 "deployApp"
}