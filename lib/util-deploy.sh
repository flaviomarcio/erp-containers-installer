#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${STACK_INSTALLER_DIR}/lib/util-build.sh
. ${STACK_INSTALLER_DIR}/lib/util-prepare.sh
. ${STACK_INSTALLER_DIR}/lib/util-selectors.sh


function deployImage()
{
  logStart ${1} "deployImage"
  if [[ ${2} != "" && ${3} != "" ]]; then
    export STACK_ACTION=${2}
    export STACK_PROJECT=${3}
  fi
  logMethod ${1} "action: ${STACK_ACTION}"
  logMethod ${1} "project: ${STACK_PROJECT}"

  RUN_FILE="${STACK_INSTALLER_BIN_DIR}/prepare-${APPLICATION_STACK}.env"
  if [[ -f ${RUN_FILE} ]]; then
    runSource "$(incInt ${1})" ${RUN_FILE} 
  fi

  buildProjectPrepare "$(incInt ${1})" ${STACK_ACTION} ${STACK_PROJECT}
  if ! [ "$?" -eq 1 ]; then
    logError ${1} "deployApp: buildProjectPrepare ${1} ${STACK_ACTION} ${STACK_PROJECT}"
  else
    buildRegistryImage "$(incInt ${1})"

    rm -rf ${BUILD_TEMP_DIR}
    makeDir "$(incInt ${1})" ${BUILD_TEMP_DIR} 777
    makeDir "$(incInt ${1})" ${BUILD_TEMP_APP_DATA_DIR} 777
    
    export APPLICATION_FILTER=app*.jar
  fi

  logFinished ${1} "deployImage"
  return 1
}


function deployApp()
{
  logStart ${1} "deployApp"
  if [[ ${2} != "" && ${3} != "" ]]; then
    export STACK_ACTION=${2}
    export STACK_PROJECT=${3}
  fi
  logMethod ${1} "action: ${STACK_ACTION}"
  logMethod ${1} "project: ${STACK_PROJECT}"

  buildProjectPrepare "$(incInt ${1})" ${STACK_ACTION} ${STACK_PROJECT}
  if ! [ "$?" -eq 1 ]; then
    logError ${1} "deployApp: buildProjectPrepare ${1} ${STACK_ACTION} ${STACK_PROJECT}"
  else
    echo $'\n'"Deploying stack:[${STACK_PROJECT}], image:[${BUILD_DEPLOY_IMAGE_NAME}]"
    echo "  DNS Service: ${APPLICATION_DEPLOY_HOSTNAME}"

    logInfo ${1} "action" ${STACK_ACTION}
    logInfo ${1} "project" ${STACK_PROJECT}


    cdDir ${1} ${BUILD_TEMP_DIR};
    if ! [ "$?" -eq 1 ]; then
      return 0;
    fi

    logInfo ${1} "build-dir" ${PWD}

    CHECK=$(docker stack ls | grep ${APPLICATION_DEPLOY_CONTAINER_NAME})
    if [[ ${CHECK} != "" ]]; then
      if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
        logCommand ${1} "docker stack rm ${APPLICATION_DEPLOY_CONTAINER_NAME}"
        docker stack rm ${APPLICATION_DEPLOY_CONTAINER_NAME}
      else
        echo $(docker stack rm ${APPLICATION_DEPLOY_CONTAINER_NAME})&>/dev/null&>/dev/null
      fi    
    fi

    COMPOSE_SRC=${STACK_INSTALLER_DOCKER_COMPOSE_DIR}/${DOCKER_STACK_FILE_NAME}
    COMPOSE_DST=${PWD}/docker-compose.yml
    logInfo ${1} "source" ${COMPOSE_SRC}
    logInfo ${1} "destine" ${COMPOSE_DST}

    if ! [[ -f ${COMPOSE_SRC} ]]; then
      log "Invalid compose file: ${COMPOSE_SRC}"
    else    
      logCommand ${1} "rm -rf_${COMPOSE_DST}"
      logCommand ${1} "cp -r ${COMPOSE_SRC} ${COMPOSE_DST}"
      rm -rf ${COMPOSE_DST}
      cp -r ${COMPOSE_SRC} ${COMPOSE_DST}

      logCommand ${1} "docker stack deploy -c ${COMPOSE_DST} ${APPLICATION_DEPLOY_CONTAINER_NAME}"
      logInfo ${1} "docker-image-name" "${APPLICATION_DEPLOY_IMAGE}"

      if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
        docker stack deploy -c ${COMPOSE_DST} ${APPLICATION_DEPLOY_CONTAINER_NAME}
      else
        echo $(docker stack deploy -c ${COMPOSE_DST} ${APPLICATION_DEPLOY_CONTAINER_NAME})&>/dev/null
      fi
    fi

  fi
  logFinished ${1} "deployApp"
}

function deployImageApp()
{
  logStart ${1} "deployImageApp"
  if [[ ${2} != "" && ${3} != "" ]]; then
    export STACK_ACTION=${2}
    export STACK_PROJECT=${3}
  fi
  logInfo ${1} "action" ${STACK_ACTION}
  logInfo ${1} "project" ${STACK_PROJECT}
  deployImage "$(incInt ${1})" ${STACK_ACTION} ${STACK_PROJECT}
  deployApp "$(incInt ${1})" ${STACK_ACTION} ${STACK_PROJECT}
  logFinished ${1} "deployImageApp"
}


function deployImageAppAll()
{
  idt="$(incInt ${1})"
  logStart ${idt} "deployImageAppAll"
  if [[ ${2} != "" && ${3} != "" ]]; then
    export STACK_ACTION=${2}
    export STACK_PROJECT=${3}
  fi

  PROJECT_LIST=("$(getProjects)")
  for PROJECT in "${FILENAME_STEP_LIST[@]}"
  do
    export STACK_PROJECT=${PROJECT}
    deployImageApp ${idt} ${STACK_ACTION} ${STACK_PROJECT}
  done

  logFinished ${idt} "deployImageAppAll"
}