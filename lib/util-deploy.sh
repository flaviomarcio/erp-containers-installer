#!/bin/bash

. ${INSTALLER_DIR}/lib/util.sh
. ${INSTALLER_DIR}/lib/util-build.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh


function deployImage()
{
  logStart "deployImage"
  if [[ ${1} != "" && ${2} != "" ]]; then
    export STACK_ACTION=${1}
    export STACK_PROJECT=${2}
  fi
  utilPrepareStack
  RUN_FILE="${STACK_INSTALLER_BIN_DIR}/prepare-${APPLICATION_STACK}.env"

  runSource ${RUN_FILE}

  rm -rf ${BUILD_TEMP_DIR}
  makeDir ${BUILD_TEMP_DIR} 777
  makeDir ${BUILD_TEMP_APP_DIR} 777
  
  export APPLICATION_FILTER=app*.jar
  export DOCKER_FILE_SRC=${STACK_INSTALLER_DOCKER_FILE_DIR}/${DOCKER_FILE_NAME}
  export DOCKER_FILE_DST=${BUILD_TEMP_DIR}/Dockerfile

  logFinished "deployImage"
  return 1
}


function deployApp()
{
  logStart "deployApp"
  if [[ ${1} != "" && ${2} != "" ]]; then
    export STACK_ACTION=${1}
    export STACK_PROJECT=${2}
  fi

  utilPrepareStack

  cdDir ${BUILD_TEMP_SOURCE_DIR};
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  echo $'\n'"Deploying stack:[${STACK_PROJECT}], image:[${BUILD_DEPLOY_IMAGE_NAME}]"
  echo "  DNS Service: ${APPLICATION_DEPLOY_HOSTNAME}"

  CHECK=$(docker stack ls | grep ${APPLICATION_CONTAINER_NAME})
  if [[ ${CHECK} != "" ]]; then
    if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
      log "docker stack rm ${APPLICATION_CONTAINER_NAME}"
      docker stack rm ${APPLICATION_CONTAINER_NAME}
    else
      echo $(docker stack rm ${APPLICATION_CONTAINER_NAME})&>/dev/null
    fi    
  fi

  COMPOSE_SRC=${STACK_INSTALLER_DOCKER_COMPOSE_DIR}/${DOCKER_STACK_FILE_NAME}
  COMPOSE_DST=${BUILD_TEMP_SOURCE_DIR}/${DOCKER_STACK_FILE_NAME}

  rm -rf ${COMPOSE_DST}
  cp -r ${COMPOSE_SRC} ${COMPOSE_DST}

  echo "docker stack deploy -c ${DOCKER_STACK_FILE_NAME} ${APPLICATION_CONTAINER_NAME}"
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    docker stack deploy -c ${COMPOSE_SRC} ${APPLICATION_CONTAINER_NAME}
  else
    echo $(docker stack deploy -c ${COMPOSE_SRC} ${APPLICATION_CONTAINER_NAME})&>/dev/null
  fi
  logFinished "deployApp"
}

function deployImageApp()
{
  logStart "deployImageApp"
  if [[ ${1} != "" && ${2} != "" ]]; then
    export STACK_ACTION=${1}
    export STACK_PROJECT=${2}
  fi
  buildProjectPrepare ${STACK_ACTION} ${STACK_PROJECT}
  deployApp ${STACK_ACTION} ${STACK_PROJECT}
}