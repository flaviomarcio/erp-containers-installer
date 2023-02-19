#!/bin/bash

. ${INSTALLER_DIR}/lib/util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh

function buildPrepareProject()
{
  log -l $'\n'"run::prepare_project(${STACK_ACTION},${STACK_PROJECT}):start"
  export STACK_ACTION=${1}
  export STACK_PROJECT=${2}
  export STACK_APPLICATION_FILE=${STACK_APPLICATION_PROJECT_DIR}/${STACK_PROJECT}
  runSource ${STACK_APPLICATION_FILE}

  RUN_FILE=${STACK_ENV_DIR}/run-prepare-${APPLICATION_STACK}.env
  runSource ${RUN_FILE}

  log "Running ${STACK_ACTION}"
  RUN_FILE=${STACK_BIN_DIR}/${STACK_ACTION}
  chmod +x ${RUN_FILE}
  runSource ${RUN_FILE}
  log -l $'\n'"run::prepare_project(${STACK_ACTION},${STACK_PROJECT}):finished"
}

function buildProjectPull()
{
  GIT_REPOSITORY=${1}
  GIT_BRANCH=${2}

  echo $'\n'"Cloning repository: [${GIT_REPOSITORY}:${GIT_BRANCH}]"
  rm -rf ${BUILD_SOURCE_DIR};
  echo $(git clone ${GIT_REPOSITORY} src)>/dev/null    
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    git config pull.rebase false
    git reset --hard
    git checkout ${GIT_BRANCH}
    git pull origin ${GIT_BRANCH}
  else
    echo $(git config pull.rebase false)>/dev/null
    echo $(git reset --hard)>/dev/null
    echo $(git checkout ${GIT_BRANCH})>/dev/null
    echo $(git pull origin ${GIT_BRANCH})>/dev/null
  fi

  if [[ -d ${BUILD_SOURCE_DIR} ]]; then
    return 1;
  else
    return 0;
  fi   
}

function buildProjectSource()
{
  echo $'\n'"Building source [${BUILD_IMAGE_NAME}]"        
  
  log -lv "mvn clean install -DskipTests"
  cd ${BUILD_SOURCE_DIR}
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    mvn clean install -DskipTests
  else
    echo $(mvn clean install -DskipTests)>/dev/null
  fi
  cd ${ROOT_DIR}
  rm -rf ${BUILD_APP_JAR};
  export APPLICATION_JAR=$(find ${BUILD_APP_JAR} -name 'app*.jar')
  log -lv "cp -r ${APPLICATION_JAR} ${BUILD_APP_JAR}"      
  cp -r ${APPLICATION_JAR} ${BUILD_APP_JAR}
}

function buildDockerFile()
{
  IMAGE_NAME=${1}
  FILE_SRC={2}
  FILE_DST={2}
  echo $'\n'"Building docker image [${IMAGE_NAME}]"
  echo $(rm -rf ${FILE_DST})>/dev/null
  if ! [[ -f ${FILE_SRC} ]]; then
    echo $'\n'"Docker file not found [${FILE_SRC}]"
    return 1;
  else
    cp -r ${FILE_SRC} ${FILE_DST}
    cd ${BUILD_DIR}
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
  URL_TAG=${STACK_REGISTRY_DNS}/${IMAGE_NAME}
  echo $'\n'"Sending docker image [${IMAGE_NAME}] to registry"
  if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    docker image tag ${IMAGE_NAME} ${TAG_URL}
  else
    echo $(docker image tag ${IMAGE_NAME} ${TAG_URL})&>/dev/null
  fi
  log -lvs "docker push ${TAG_URL}"
  if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    docker push ${TAG_URL}
  else
    echo $(docker push ${TAG_URL})&>/dev/null
  fi
}

function buildRegistryImage()
{
  if [[ -d ${BUILD_APP_BIN_SRC_DIR} ]]; then
    log "Invalid \${BUILD_APP_BIN_SRC_DIR}:${BUILD_APP_BIN_SRC_DIR}"
    rm -rf ${BUILD_APP_DIR}
    cp -r ${BUILD_APP_BIN_SRC_DIR} ${BUILD_APP_DIR}
  elif [[ -f ${DOCKER_FILE_SRC} ]]; then
    buildDockerFile ${BUILD_IMAGE_NAME} ${DOCKER_FILE_SRC} ${DOCKER_FILE_DST}
    buildRegistryPush ${BUILD_IMAGE_NAME}
  elif buildProjectPull ${APPLICATION_GIT} ${APPLICATION_GIT_BRANCH}; then
    buildProjectSource ${BUILD_SOURCE_DIR}
  else
    log "Invalid build mode"
    return 1;   
  fi
  return 1;   
}

