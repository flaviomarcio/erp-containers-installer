#!/bin/bash

. ${INSTALLER_DIR}/lib/util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh

function buildProjectPrepare()
{
  logStart "buildProjectPrepare"
  if [[ ${1} != "" && ${2} != "" ]]; then
    export STACK_ACTION=${1}
    export STACK_PROJECT=${2}
  fi
  export STACK_APPLICATIONS_RUN=${STACK_APPLICATIONS_PROJECT_DIR}/${STACK_PROJECT}

  RUN_FILE=${STACK_APPLICATIONS_RUN}

  logMethod "run ${RUN_FILE}"
  runSource ${RUN_FILE}  1
  logFinished "buildProjectPrepare"
}

function buildProjectPull()
{
  logStart "buildProjectPull"
  GIT_REPOSITORY=${APPLICATION_GIT}
  GIT_BRANCH=${APPLICATION_GIT_BRANCH}

  rm -rf ${BUILD_TEMP_SOURCE_DIR};

  if [[ ${GIT_REPOSITORY} == "" ]]; then
    return 1
  fi

  echo $'\n'"Cloning repository: [${GIT_REPOSITORY}:${GIT_BRANCH}]"
  cdDir ${BUILD_TEMP_DIR}
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    git clone ${GIT_REPOSITORY} src
  else
    echo $(git clone ${GIT_REPOSITORY} src)>/dev/null    
  fi

  cdDir ${BUILD_TEMP_SOURCE_DIR};
  if ! [ "$?" -eq 1 ]; then
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
  logFinished "buildProjectPull"
}

function buildProjectSource()
{
  logStart "buildProjectSource"
  log -lvs "call buildProjectSource:"
  log -lvs ".    - target: ${BUILD_TEMP_SOURCE_DIR} "

  cdDir ${BUILD_TEMP_SOURCE_DIR}
  if ! [ "$?" -eq 1 ]; then
    log -lvs ".    - error: dir not found, fileName: ${BUILD_TEMP_SOURCE_DIR}"
    return 0;
  fi

  if ! fileExists "pom.xml"; then
    log -lvs ".    - manven: ignored"
    return 1;
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

  log -lvs ".    - result: success"
  return 1;
}

function buildDockerFile()
{
  logStart "buildDockerFile"
  IMAGE_NAME=${1}
  FILE_SRC=${2}
  FILE_DST=${3}
  echo $'\n'"Building docker image [${IMAGE_NAME}]"
  echo $(rm -rf ${FILE_DST})>/dev/null
  if ! [[ -f ${FILE_SRC} ]]; then
    echo $'\n'"Docker file not found [${FILE_SRC}]"
    __RETURN=1;
  else
    cp -r ${FILE_SRC} ${FILE_DST}
    cd ${BUILD_TEMP_DIR}
    if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
      log "docker build -t ${IMAGE_NAME} ."
      docker build -t ${IMAGE_NAME} .
    else
      echo $(docker build -t ${IMAGE_NAME} .)>/dev/null
    fi
    cd ${ROOT_DIR}
    __RETURN=1;
  fi
  logFinished "buildDockerFile"
  return ${__RETURN}
}

function buildRegistryPush()
{
  logStart "buildRegistryPush"
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

  #CHECK=$(docker image ls | grep ${IMAGE_NAME})
  #if [[ ${CHECK} != "" ]]; then
  #  echo $(docker image rm -f $(docker image ls | grep ${IMAGE_NAME} | awk '{print $3}' | sort --unique ))&>/dev/null
  #fi
  logFinished "buildRegistryPush"
}

function buildRegistryImage()
{
  logStart "buildRegistryImage"
  if [[ -d ${BUILD_TEMP_APP_BIN_SRC_DIR} ]]; then
    rm -rf ${BUILD_TEMP_APP_DIR}
    cp -r ${BUILD_TEMP_APP_BIN_SRC_DIR} ${BUILD_TEMP_APP_DIR}
  fi

  buildProjectPull
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  buildProjectSource
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  buildDockerFile ${BUILD_DEPLOY_IMAGE_NAME} ${DOCKER_FILE_SRC} ${DOCKER_FILE_DST}
  buildRegistryPush ${BUILD_DEPLOY_IMAGE_NAME}
  logFinished "buildRegistryImage"
  return 1;   
}

