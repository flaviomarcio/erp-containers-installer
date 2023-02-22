#!/bin/bash

if [[ ${ROOT_DIR} == "" ]]; then
  export ROOT_DIR=${PWD}
fi
export STACK_RUN_BIN=${ROOT_DIR}/bin


function toInt()
{
  v=${1}
  [ ! -z "${v##*[!0-9]*}" ] && echo -n ${v} || echo 0;
}

function incInt()
{
  v=$(toInt ${1})
  let "v=${v} + 1"
  echo ${v}
}

function logIdent()
{
  IDENT=$(toInt ${1})
  CHAR=${2}

  if [[ ${CHAR} == "" ]]; then
    CHAR="."
  fi

  if [[ ${IDENT} == "" ]]; then
    echo -n ${CHAR}
    return;
  fi

  for i in $(seq 1 4);
  do
    TEXT="${TEXT}${CHAR}"
  done
  TEXT="${TEXT}"
  
  for i in $(seq 1 ${IDENT})
  do
    CHARS="${TEXT}${CHARS}"
  done
  echo -n ${CHARS}

  return;
}

function log()
{
  if [[ ${1} != "" && ${1} == -* ]]; then
    FLG_1="${1}"
    FLG_2="${2}"
  else
    FLG_1="${1} ${2}"
    FLG_2=
  fi

  if [[ ${FLG_1} == "-l" || ${FLG_1} == "-lv" || ${FLG_1} == "-lvs" ]]; then
    
    if [[ ${FLG_2} != "" ]]; then
      if [[ ${FLG_1} == "-l" && ${STACK_LOG} == 1 ]]; then
        echo ".  ${FLG_2}"
      elif [[ ${FLG_1} == "-lv" && ${STACK_LOG_VERBOSE} == 1 ]]; then
        echo ".    ${FLG_2}"
      elif [[ ${FLG_1} == "-lvs" && ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
        echo ".       ${FLG_2}"
      fi
    fi
  elif [[ ${FLG_1} != "" ]]; then
    echo ${FLG_1}
  fi
}

function logMethod()
{
  log -lvs "$(logIdent ${1})${2}"
}

function logForce()
{
  v=${2}
  log "$(logIdent ${1}) ${v}"
}

function logInfo()
{
  let "IDENT = $(toInt ${1}) + 1"
  if [[ ${2} != "" && ${3} != "" ]]; then
    LOG="-${2}:${3}"
  else
    LOG="-${2}"
  fi
  if [[ ${LOG} != "" ]]; then
    logMethod ${IDENT} ${LOG}
  fi
}

function logCommand()
{
  logInfo ${1} "command" ${2}
}

function logTarget()
{
  logInfo ${1} "target" ${2}
}

function logError()
{
  if [[ ${2} != "" ]]; then
    #logForce ${1} "error: ${2}"
    logInfo ${1} "error: ${2}"
  fi
}

function logSuccess()
{
  if [[ ${2} == "" ]]; then
    logInfo ${1} "result" "success"
  else
    logInfo ${1} "result" "success" ${2}
  fi
}

function logStart()
{
  logMethod ${1} "started"
  if [[ ${2} != "" ]]; then
    logTarget ${1} ${2}
  fi
}

function logFinished()
{
  if [[ ${2} != "" ]]; then
    logInfo ${1} "message" ${2}
  fi
  logMethod ${1} "finished"
}

function runSource()
{
  RUN_FILE=${2}
  logStart ${1} "runSource"
  logTarget ${1} ${FILE}

  RUN_CHARS=$(logIdent ${1} "." })

  logTarget ${1} ${RUN_FILE}
  if [[ ${RUN_FILE} == "" ]]; then
    logError ${1} "run-file-is-empty"
  elif ! [[ -f ${RUN_FILE} ]]; then
    logError ${1} "run-file-not-found"
  else
    chmod +x ${RUN_FILE}
    if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
      source ${RUN_FILE}
    else
      echo $(source ${RUN_FILE})&>/dev/null
    fi
    logSuccess ${1}
    logFinished ${1} "runSource ${RUN_FILE}"
    return 1
  fi
  logFinished ${1} "runSource ${RUN_FILE}"
  return 0
}

function cdDir()
{
  NEW_DIR=${2}
  OLD_DIR=${PWD}
  logStart ${1} "cdDir"
  logInfo ${1} "of" ${OLD_DIR}
  logInfo ${1} "to" ${NEW_DIR}
  if ! [[ -d ${NEW_DIR} ]]; then
    logError ${1} "invalid-dir:${NEW_DIR}"
    return 0;
  fi
  cd ${NEW_DIR}
  if [[ ${PWD} != ${NEW_DIR} ]]; then
    logError ${1} "no-access-dir:${NEW_DIR}"
    logFinished ${1} "cdDir"
    return 0;
  fi
  logSuccess ${1}
  logFinished ${1} "cdDir"
  return 1;
}

function fileExists()
{
  logStart ${1} "fileExists"
  TARGET=${2}
  DIR=${3}
  if [[ ${DIR} == "" ]]; then
    DIR=${PWD}
  fi

  logTarget ${1} ${TARGET}
  logInfo ${1} "dir" ${DIR}
  FILE=${DIR}/${TARGET}
  if ! [[ -f ${FILE} ]]; then
    logError ${1} "file-not-found|fileName:${FILE}"
    logFinished ${1} "fileExists"
    return 0;
  fi
  logSuccess "success"
  logFinished ${1} "fileExists"
  return 1;
}


function makeDir()
{
  logStart ${1} "makeDir"
  MAKE_DIR=${2}
  MAKE_PERMISSION=${3}

  logTarget ${1} ${MAKE_DIR}
  logInfo ${1} "permission" ${MAKE_PERMISSION}

  if [[ ${MAKE_DIR} == "" || ${MAKE_PERMISSION} == "" ]]; then
    logError ${1} "Invalid-parameters:MAKE_DIR==${MAKE_DIR},MAKE_PERMISSION==${MAKE_PERMISSION}"
    return;
  fi

  if [[ ${MAKE_DIR} == "" ]]; then
    MSG="dir-is-empty"
    logError ${1} ${MSG}
    return;
  fi

  if ! [[ -d ${MAKE_DIR}  ]]; then
    mkdir -p ${MAKE_DIR}
    if ! [[ -d ${MAKE_DIR}  ]]; then
      logError ${1} "no-create-dir:${MSG}"
      return 0
    fi
  fi  


  if [[ ${MAKE_PERMISSION} != "" ]]; then
    chmod ${MAKE_PERMISSION} ${MAKE_DIR};
  fi

  logSuccess ${1}
  logFinished ${1} "makeDir"
  return 1;
}

function copyFile()
{
  logStart ${1} "copyFile"
  SRC=$1
  DST=$2

  logTarget ${1} ${SRC}
  logInfo ${1} "destine" ${DST}

  log -lv "Copying ${SRC} to ${DST}"
  if [[ -f ${SRC} ]]; then
    logError ${1} "sources-does-not-exists[${SRC}]"
  elif [[ -f ${DST} ]]; then
    logError ${1} "destine-exists-[${DST}]"
  else
    cp -r ${SRC} ${DST}
    if [[ -f ${DST} ]]; then
      logSuccess ${1}
    fi
  fi
  logFinished ${1} "copyFile"
}

function copyFileIfNotExists()
{
  logStart ${1} "copyFileIfNotExists"
  SRC=$1
  DST=$2
  
  logTarget ${1} ${SRC}
  logInfo ${1} "destine" ${DST}
  if ! [[ -f ${SRC} ]]; then
    logError ${1} "source-does-not-exists-[${SRC}]"
  else
    if [[ -d ${DST} ]]; then
      rm -rf ${DST}
      logInfo ${1} "remove" ${DST}
    fi
    cp -r ${SRC} ${DST}
    if [[ -d ${DST} ]]; then
      logSuccess ${1} "success"
    fi
  fi
  logFinished ${1} "copyFileIfNotExists"
}

function utilInitialize()
{
  for PARAM in "$@"
  do
    if [[ $PARAM == "-l" ]]; then
      export STACK_LOG=1            
    elif [[ $PARAM == "-lv" ]]; then
      export STACK_LOG=1            
      export STACK_LOG_VERBOSE=1            
    elif [[ $PARAM == "-lvs" ]]; then
      export STACK_LOG=1            
      export STACK_LOG_VERBOSE=1            
      export STACK_LOG_VERBOSE_SUPER=1
    fi
  done

  if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    echo "Log super verbose enabled"
  elif [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    echo "Log verbose enabled"
  elif [[ ${STACK_LOG} == 1 ]]; then
    echo "Log enabled"
  fi

  export PATH=${PATH}:${STACK_RUN_BIN}
}

function envsParserFile()
{
  logStart ${1} "envsParserFile"
  FILE=$1
  if [[ -f ${FILE} ]]; then
    ENVSLIST=()
    ENVSLIST+=($(printenv | grep STACK_ENVIRONMENT ))
    ENVSLIST+=($(printenv | grep STACK_DOMAIN ))
    ENVSLIST+=($(printenv | grep STACK_PROTOCOL ))
    ENVSLIST+=($(printenv | grep STACK_SERVICE ))
    ENVSLIST+=($(printenv | grep STACK_SERVICE_DNS ))
    ENVSLIST+=($(printenv | grep STACK_RESOURCE ))
    ENVSLIST+=($(printenv | grep STACK_NETWORK ))
    ENVSLIST+=($(printenv | grep STACK_PROXY ))
    ENVSLIST+=($(printenv | grep STACK_LOG ))

    logInfo ${1} "replace-envs-in-${FILE}"
    for ENV in "${ENVSLIST[@]}"
    do
      ENV=(${ENV//=/ })
      replace="\${${ENV[0]}}"
      replacewith=${ENV[1]}
      if [[ ${replace} == "" || ${replace} == "_" || ${replacewith} == ""  ]]; then
        continue;
      fi
      FILE_BACK=${FILE}-sed.bak
      rm -rf ${FILE_BACK}
      cp -r ${FILE} ${FILE_BACK}
      echo $(sed -i "s/${replace}/${replacewith}/g" ${FILE})&>/dev/null
    done

    logFinished ${1} "envsParserFile"
    return 1;
  fi
  logFinished ${1} "envsParserFile"
  return 0;
}


function envsParserDir()
{
  logStart ${1} "envsParserDir"
  export DIR=$1
  export EXT=$2

  if [[ ${DIR} == "" || ${EXT} == "" ]]; then
    if [[ -d ${DIR} ]]; then
      logInfo ${1} "parser-dir" ${DIR}
      FILELIST=($(find ${DIR} -name ${EXT}))
      for FILE in "${FILELIST[@]}"
      do
        if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
          logInfo ${1} "parser-file" ${FILE}
        fi
        envsParserFile $(incInt ${1}) ${FILE}
      done
    fi
  fi

  logFinished ${1} "envsParserDir"
  return 1;
}