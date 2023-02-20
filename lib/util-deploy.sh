#!/bin/bash

. ${INSTALLER_DIR}/lib/util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh
. ${INSTALLER_DIR}/lib/util-build.sh


function deployImage()
{
  logStart "deployImage"
  utilPrepareStack
  RUN_FILE="${STACK_INSTALLER_BIN_DIR}/prepare-${APPLICATION_STACK}.env"

  if [[ -f ${RUN_FILE} ]]; then
    log -lv "runSource ${RUN_FILE}"
    runSource ${RUN_FILE}
  fi

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
  utilPrepareStack
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

  RUN_FILE_COMPOSE=${STACK_INSTALLER_DOCKER_COMPOSE_DIR}/${DOCKER_STACK_FILE_NAME}

  echo "docker stack deploy -c ${RUN_FILE_COMPOSE} ${APPLICATION_CONTAINER_NAME}"
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    docker stack deploy -c ${RUN_FILE_COMPOSE} ${APPLICATION_CONTAINER_NAME}
  else
    echo $(docker stack deploy -c ${RUN_FILE_COMPOSE} ${APPLICATION_CONTAINER_NAME})&>/dev/null
  fi
  logFinished "deployApp"
}

function deployImageApp()
{
  logStart "deployImageApp"
  buildProjectPrepare ${ACTION} ${STACK_PROJECT}
  deployApp
  logFinished "deployImageApp"
}