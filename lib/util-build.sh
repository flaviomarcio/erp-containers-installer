#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh

function buildProjectPrepare()
{
  logStart ${1} "buildProjectPrepare"
  if [[ ${2} != "" && ${3} != "" ]]; then
    export STACK_ACTION=${2}
    export STACK_PROJECT=${3}
  fi
  
  export STACK_APPLICATIONS_RUN=${STACK_APPLICATIONS_PROJECT_DIR}/${STACK_PROJECT}
  RUN_FILE=${STACK_APPLICATIONS_RUN}
  runSource "$(incInt ${1})" ${RUN_FILE}
  if ! [ "$?" -eq 1 ]; then
    logFinished ${1} "buildProjectPrepare on execute ${STACK_APPLICATIONS_RUN}"
    return 0;
  fi

  utilPrepareStack "$(incInt ${1})" ${STACK_ACTION} ${STACK_PROJECT}
  logFinished ${1} "buildProjectPrepare"
  return 1;
}

function buildProjectCopy()
{
  logStart ${1} "buildProjectCopy"

  rm -rf ${BUILD_TEMP_DIR}
  makeDir "$(incInt ${1})" ${BUILD_TEMP_DIR} 777
  makeDir "$(incInt ${1})" ${BUILD_TEMP_APP_DATA_DIR} 777
  makeDir "$(incInt ${1})" ${APPLICATION_DEPLOY_APP_DIR} 777

  DESTINE_DIR=${BUILD_TEMP_APP_DATA_DIR}

  rm -rf ${DESTINE_DIR}

  if [[ -d ${BUILD_TEMP_APP_BIN_SRC_DIR} ]]; then
    logCommand ${1} "cp -r ${BUILD_TEMP_APP_BIN_SRC_DIR} ${DESTINE_DIR}"
    cp -r ${BUILD_TEMP_APP_BIN_SRC_DIR} ${DESTINE_DIR}
  fi

  if ! [[ -d ${DESTINE_DIR} ]]; then
    mkdir -p ${DESTINE_DIR}
  fi

  #copy installer
  cp -r ${INSTALLER_DIR}/lib ${APPLICATION_DEPLOY_APP_DIR}/installer-lib
 
  echo "#!/bin/bash" > ${APPLICATION_DEPLOY_BASHRC_FILE} 

  TARGET_DIR_LIST=( ${STACK_INSTALLER_DOCKER_CONF_DIR} ${STACK_INSTALLER_DOCKER_FILE_DIR} )
  TARGET_LIST=( ${APPLICATION_STACK} ${STACK_PROJECT} )

  for TARGET_ITEM in "${TARGET_LIST[@]}"
  do
    for TARGET_PATH in "${TARGET_DIR_LIST[@]}"
    do
      TARGET_DIR="${TARGET_PATH}/${TARGET_ITEM}"
      if [[ -d ${TARGET_DIR} ]]; then
        logCommand ${1} "cp -r -T ${TARGET_DIR} ${APPLICATION_DEPLOY_APP_DIR}"
        cp -r -T ${TARGET_DIR} ${APPLICATION_DEPLOY_APP_DIR}

        BASHRC_LIST=$(find ${TARGET_DIR} -iname '*bashrc.sh');
        for BASHRC_FILE in "${BASHRC_LIST[@]}"
        do 
          if [[ -f ${BASHRC_FILE} ]]; then
            echo "" >> ${APPLICATION_DEPLOY_BASHRC_FILE} 
            echo "# source ${BASHRC_FILE}">>${APPLICATION_DEPLOY_BASHRC_FILE} 
            echo "" >> ${APPLICATION_DEPLOY_BASHRC_FILE} 
            cat ${BASHRC_FILE} >> ${APPLICATION_DEPLOY_BASHRC_FILE} 
          fi
        done
      fi
    done
  done
  echo "" >> ${APPLICATION_DEPLOY_BASHRC_FILE} 

  logFinished ${1} "buildProjectCopy"
  return 1;
}

function buildProjectPull()
{
  logStart ${1} "buildProjectPull"

  GIT_REPOSITORY=${APPLICATION_GIT}
  GIT_BRANCH=${APPLICATION_GIT_BRANCH}

  rm -rf ${BUILD_TEMP_SOURCE_DIR};

  if [[ ${GIT_REPOSITORY} == "" ]]; then
    return 1
  fi

  logTarget ${1} "${APPLICATION_GIT}"

  log $'\n'"Cloning repository: [${GIT_REPOSITORY}:${GIT_BRANCH}]"
  cdDir ${1} ${BUILD_TEMP_DIR}
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    git clone ${GIT_REPOSITORY} src
  else
    echo $(git clone ${GIT_REPOSITORY} src)>/dev/null    
  fi

  cdDir ${1} ${BUILD_TEMP_SOURCE_DIR}
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  PROJECT_INIT=${BUILD_TEMP_SOURCE_DIR}/initrepository
  if [[ -f ${PROJECT_INIT} ]]; then
      cd ${BUILD_TEMP_SOURCE_DIR}
      logInfo ${1} $'\n'"Init repository: [${GIT_REPOSITORY}:${GIT_BRANCH}]"
      echo $( ${PROJECT_INIT} )&>/dev/null
  fi

  cdDir ${1} ${BUILD_TEMP_SOURCE_DIR}
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

  logFinished ${1} "buildProjectPull"
  if [[ -d ${BUILD_TEMP_SOURCE_DIR} ]]; then
    return 1;
  else
    return 0;
  fi   
}

function buildQtProject()
{
  RETURN=0
  logStart ${1} "buildQtProject"
  export GIT_REPOSITORY=git@github.com:flaviomarcio/qtreforce-sdk.git
  export GIT_BRANCH=master

  if ! [[ -d ${BUILD_TEMP_SOURCE_DIR} ]]; then
    logFinished ${1} "buildQtProject"
    return 1;
  fi

  BUILD_TEMP_BUILD_DIR=${BUILD_TEMP_DIR}/build-temp

  QT_BIN_DIR=${PUBLIC_LIB_DIR}/qt/${QT_VERSION}/bin
  QT_QMAKE=${QT_BIN_DIR}/qmake

  if ! [[ -f ${QT_QMAKE} ]]; then
    logError ${1} "Invalid QMAKE: ${QT_QMAKE}"
    logFinished ${1} "buildQtProject"
    return 0;
  fi

  find ${BUILD_TEMP_SOURCE_DIR} -maxdepth 1 -name '*.pro'

  PROJECT_LIST=($(find ${BUILD_TEMP_SOURCE_DIR} -maxdepth 1 -name '*.pro'))

  mkdir -p ${BUILD_TEMP_BUILD_DIR}

  for PROJECT_FILE in "${PROJECT_LIST[@]}"
  do
      PROJECT_DIR=$(dirname ${PROJECT_FILE})
      PROJECT_NAME=$(basename ${PROJECT_FILE})
      PROJECT_BUILD_DIR=${BUILD_TEMP_BUILD_DIR}/${PROJECT_NAME}
      mkdir -p ${PROJECT_BUILD_DIR}
      cd ${PROJECT_BUILD_DIR}

      logTarget ${1} ${PROJECT_FILE}
      logCommand ${1} "${QT_QMAKE} -spec linux-g++ CONFIG+=realease CONFIG-=qml_debug ${PROJECT_FILE}"
      logCommand ${1} "make -j12"
      

      if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
        ${QT_QMAKE} -spec linux-g++ CONFIG+=realease CONFIG-=qml_debug ${PROJECT_FILE}
        make -j12
      else
        echo $(${QT_QMAKE} -spec linux-g++ CONFIG+=realease CONFIG-=qml_debug ${PROJECT_FILE})&>/dev/null
        echo $(make -j12)&>/dev/null
      fi

      BIN_LIST=($(find ${PROJECT_BUILD_DIR} -executable -type f))

      for FILE_SRC in "${BIN_LIST[@]}"
      do 
          if [[ ${APPLICATION_TEMPLATE} == "lib" ]]; then
            FILE_DST=${PUBLIC_LIB_DIR}/$(basename ${FILE_SRC})
          else
            FILE_DST=${BUILD_TEMP_APP_DATA_DIR}/$(basename ${FILE_SRC})
          fi
          if [[ -f ${FILE_DST} ]]; then
            rm -rf ${FILE_DST};
          fi
          logCommand ${1} "cp -r ${FILE_SRC} ${FILE_DST}"
          cp -r ${FILE_SRC} ${FILE_DST}
          if [[ -f ${FILE_DST} ]]; then
            RETURN=1
          fi
      done
  done
  cd ${BUILD_TEMP_SOURCE_DIR}
  logFinished ${1} "buildQtProject"
  return ${RETURN}
}

function buildMavenJava()
{
  logStart ${1} "buildMavenJava"
  logTarget ${1} ${BUILD_TEMP_SOURCE_DIR}

  if [[ ${GIT_REPOSITORY} == "" ]]; then
    logInfo ${1} "ignored: ${BUILD_TEMP_SOURCE_DIR}"
    logMessage ${1} "No git repository"
    return 1
  fi

  cdDir 2 ${BUILD_TEMP_SOURCE_DIR}
  if ! [ "$?" -eq 1 ]; then
    logError ${1} "dir not found, fileName: ${BUILD_TEMP_SOURCE_DIR}"
    return 0;
  fi

  fileExists ${1} "pom.xml";
  if ! [ "$?" -eq 1 ]; then
    logCommand ${1} "manven:ignored"
    return 1;
  fi

  log "Building source [${BUILD_DEPLOY_IMAGE_NAME}]"
  
  logCommand 1 "mvn clean install -DskipTests"
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    mvn clean install -DskipTests
  else
    echo $(mvn clean install -DskipTests)>/dev/null
  fi
  cd ${ROOT_DIR}
  rm -rf ${BUILD_TEMP_APP_DATA_SOURCE_JAR};
  export APPLICATION_JAR=$(find ${BUILD_TEMP_SOURCE_DIR} -name 'app*.jar')
  logCommand ${1} "cp -r ${APPLICATION_JAR} ${BUILD_TEMP_APP_DATA_SOURCE_JAR}"      

  if [[ -f ${APPLICATION_JAR} ]]; then
    cp -r ${APPLICATION_JAR} ${BUILD_TEMP_APP_DATA_SOURCE_JAR}
  fi

  logSuccess ${1} "success"
  logFinished ${1} "buildMavenJava"

  if [[ -f ${BUILD_TEMP_APP_DATA_SOURCE_JAR} ]]; then
    return 1;
  fi
  return 0;  
}

function buildProjectSource()
{
  idt="$(incInt ${1})"
  logStart ${1} "buildProjectSource"
  if ! [[ -d ${BUILD_TEMP_SOURCE_DIR} ]]; then
    logInfo ${1} "No source for build, source dir: ${BUILD_TEMP_SOURCE_DIR}"
    return 1;
  fi

  CHECK=$(find ${BUILD_TEMP_SOURCE_DIR} -name 'pom.xml')
  if [[ ${CHECK} != "" ]]; then
    logCommand ${1} "buildMavenJava ${idt}"
    buildMavenJava ${idt}
    if [ "$?" -eq 1 ]; then
      return 1;
    fi
    return 0;
  fi
  
  CHECK=$(find ${BUILD_TEMP_SOURCE_DIR} -name '*.pro')
  if [[ ${CHECK} != "" ]]; then
    logCommand ${1} "buildQtProject ${idt}"
    buildQtProject ${idt}
    if [ "$?" -eq 1 ]; then
      return 1;
    fi
    return 0;
  fi
  logError ${1} "Indeterminate project type"
  logFinished ${1} "buildProjectSource"
}

function buildDockerFile()
{
  logStart ${1} "buildDockerFile"
  IMAGE_NAME=${2}
  FILE_SRC=${3}
  FILE_DST=${4}

  if [[ -d ${DOCKER_CONF_DIR} ]]; then
    cp -r -T ${DOCKER_CONF_DIR} ${BUILD_TEMP_DIR}
  fi

  log "Building docker image [${IMAGE_NAME}]"
  if ! [[ -f ${FILE_SRC} ]]; then
      logError ${1} "Docker file not found [${FILE_SRC}]"
    __RETURN=1;
  else
    rm -rf ${FILE_DST};
    cp -r ${FILE_SRC} ${FILE_DST}
    cd ${BUILD_TEMP_DIR}
    logCommand "$(incInt ${1})" "docker build -t ${IMAGE_NAME} ."
    if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
      docker build --network host -t ${IMAGE_NAME} .
    else
      echo $(docker build --network host -t ${IMAGE_NAME} .)>/dev/null
    fi
    cd ${ROOT_DIR}
    __RETURN=1;
  fi
  logFinished ${1} "buildDockerFile"
  return ${__RETURN}
}

function buildRegistryPush()
{
  logStart ${1} "buildRegistryPush"
  IMAGE_NAME=${2}
  TAG_URL=${STACK_REGISTRY_DNS}/${IMAGE_NAME}
  echo $'\n'"Sending docker image [${IMAGE_NAME}] to registry"
  logCommand ${1} "docker image tag ${IMAGE_NAME} ${TAG_URL}"
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    docker image tag ${IMAGE_NAME} ${TAG_URL}
  else
    echo $(docker image tag ${IMAGE_NAME} ${TAG_URL})&>/dev/null
  fi
  logCommand ${1} "docker push ${TAG_URL}"
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    docker push ${TAG_URL}
  else
    echo $(docker push ${TAG_URL})&>/dev/null
  fi

  #IMAGE_LIST_RM=($(docker image ls | grep ${IMAGE_NAME} | awk '{print $3}' | sort --unique ))
  #for IMAGE_ID in "${IMAGE_LIST_RM[@]}"
  #do
  #  logCommand ${1} "docker image rm -f ${IMAGE_ID}"
  #  echo $(docker image rm -f ${IMAGE_ID})&>/dev/null
  #done
  logFinished ${1} "buildRegistryPush"
  return 1
}

function buildRegistryImage()
{
  logStart ${1} "buildRegistryImage"

  buildProjectCopy "$(incInt ${1})"
  if ! [ "$?" -eq 1 ]; then
    logError ${1} "Error on buildProjectCopy"
    return 0;
  fi

  buildProjectPull "$(incInt ${1})"
  if ! [ "$?" -eq 1 ]; then
    logError ${1} "Error on buildProjectPull"
    return 0;
  fi

  buildProjectSource "$(incInt ${1})"
  if ! [ "$?" -eq 1 ]; then
    logError ${1} "Error on buildProjectSource"
    return 0;
  fi

  if [[ ${APPLICATION_TEMPLATE} == "app" || ${APPLICATION_TEMPLATE} == "web" || ${APPLICATION_TEMPLATE} == "db" ]]; then
    buildDockerFile "$(incInt ${1})" ${BUILD_DEPLOY_IMAGE_NAME} ${DOCKER_FILE_SRC} ${DOCKER_FILE_DST}
    buildRegistryPush "$(incInt ${1})" ${BUILD_DEPLOY_IMAGE_NAME}
  fi
  logFinished ${1} "buildRegistryImage"
  return ${1};   
}

