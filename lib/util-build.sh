#!/bin/bash

. ${INSTALLER_DIR}/lib/util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh

function buildPrepareProject()
{
  export STACK_ACTION=${1}
  export STACK_PROJECT=${2}
  export STACK_APPLICATIONS_FILE=${STACK_APPLICATIONS_PROJECT_DIR}/${STACK_PROJECT}
  runSource ${STACK_APPLICATIONS_FILE}

  RUN_FILE=${STACK_ENV_DIR}/run-prepare-${APPLICATION_STACK}.env
  runSource ${RUN_FILE}

  log "Running ${STACK_ACTION}"
  RUN_FILE=${STACK_INSTALLER_BIN_DIR}/${STACK_ACTION}
  chmod +x ${RUN_FILE}
  runSource ${RUN_FILE}
}

function buildProjectPull()
{
  GIT_REPOSITORY=${APPLICATION_GIT}
  GIT_BRANCH=${APPLICATION_GIT_BRANCH}

  rm -rf ${BUILD_TEMP_SOURCE_DIR};

  if [[ ${GIT_REPOSITORY} == "" ]]; then
    return 1
  fi

  echo $'\n'"Cloning repository: [${GIT_REPOSITORY}:${GIT_BRANCH}]"
  cd ${BUILD_TEMP_DIR}
  if [[ ${PWD} != ${BUILD_TEMP_DIR} ]]; then
    log "Invalid BUILD_TEMP_SOURCE_DIR==${BUILD_TEMP_SOURCE_DIR}"
    return 0;
  fi

  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    git clone ${GIT_REPOSITORY} src
  else
    echo $(git clone ${GIT_REPOSITORY} src)>/dev/null    
  fi


  if [[ -d ${BUILD_TEMP_SOURCE_DIR} ]]; then
    log "Invalid src dir==${BUILD_TEMP_SOURCE_DIR}"
    return 0;
  fi

  cd ${BUILD_TEMP_SOURCE_DIR}
  if [[ ${PWD} != ${BUILD_TEMP_SOURCE_DIR} ]]; then
    log "Invalid src dir==${BUILD_TEMP_SOURCE_DIR}/src"
    return 0;
  fi

  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    git config pull.rebase false
    git checkout ${GIT_BRANCH}
    git pull origin ${GIT_BRANCH}
  else
    echo $(git config pull.rebase false)>/dev/null
    echo $(git checkout ${GIT_BRANCH})>/dev/null
    echo $(git pull origin ${GIT_BRANCH})>/dev/null
  fi

  if [[ -d ${BUILD_TEMP_SOURCE_DIR} ]]; then
    return 1;
  else
    return 0;
  fi   
}

function buildProjectSource()
{
  if ! [[ -d ${BUILD_TEMP_SOURCE_DIR} ]]; then
    return 0;
  fi
  cd ${BUILD_TEMP_SOURCE_DIR}
  if [[ ${PWD} != ${BUILD_TEMP_SOURCE_DIR} ]]; then
    log "Invalid build dir: ${BUILD_TEMP_SOURCE_DIR}"
    exit 0;
  fi

  echo $'\n'"Building source [${BUILD_DEPLOY_IMAGE_NAME}]"        
  
  log -lv "mvn clean install -DskipTests"
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    mvn clean install -DskipTests
  else
    echo $(mvn clean install -DskipTests)>/dev/null
  fi
  cd ${ROOT_DIR}
  rm -rf ${BUILD_TEMP_APP_JAR};
  export APPLICATION_JAR=$(find ${BUILD_TEMP_SOURCE_DIR} -name 'app*.jar')
  log -lv "cp -r ${APPLICATION_JAR} ${BUILD_TEMP_APP_JAR}"      
  cp -r ${APPLICATION_JAR} ${BUILD_TEMP_APP_JAR}
  return 1;
}

function buildDockerFile()
{
  IMAGE_NAME=${1}
  FILE_SRC=${2}
  FILE_DST=${3}
  echo $'\n'"Building docker image [${IMAGE_NAME}]"
  echo $(rm -rf ${FILE_DST})>/dev/null
  if ! [[ -f ${FILE_SRC} ]]; then
    echo $'\n'"Docker file not found [${FILE_SRC}]"
    return 1;
  else
    cp -r ${FILE_SRC} ${FILE_DST}
    cd ${BUILD_TEMP_DIR}
    log -lv "docker build -t ${IMAGE_NAME} ."
    if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
      docker build -t ${IMAGE_NAME} . 
    else
      echo $(docker build -t ${IMAGE_NAME} .)>/dev/null
    fi
    cd ${ROOT_DIR}
  fi
  return 1;
}

function buildRegistryPush()
{
  IMAGE_NAME=${1}
  TAG_URL=${STACK_REGISTRY_DNS}/${IMAGE_NAME}
  echo $'\n'"Sending docker image [${IMAGE_NAME}] to registry"
  if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    log "docker image tag ${IMAGE_NAME} ${TAG_URL}"
    docker image tag ${IMAGE_NAME} ${TAG_URL}
  else
    echo $(docker image tag ${IMAGE_NAME} ${TAG_URL})&>/dev/null
  fi
  if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    log "docker push ${TAG_URL}"
    docker push ${TAG_URL}
  else
    echo $(docker push ${TAG_URL})&>/dev/null
  fi
}

function buildRegistryImage()
{
  if [[ -d ${BUILD_TEMP_APP_BIN_SRC_DIR} ]]; then
    rm -rf ${BUILD_TEMP_APP_DIR}
    cp -r ${BUILD_TEMP_APP_BIN_SRC_DIR} ${BUILD_TEMP_APP_DIR}
  fi

  if ! buildProjectPull; then
    return 0;
  fi

  if buildProjectSource; then
    return 0;
  fi
    
  buildDockerFile ${BUILD_DEPLOY_IMAGE_NAME} ${DOCKER_FILE_SRC} ${DOCKER_FILE_DST}
  buildRegistryPush ${BUILD_DEPLOY_IMAGE_NAME}
  return 1;   
}

