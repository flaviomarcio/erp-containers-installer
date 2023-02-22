#!/bin/bash

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
        echo ">> ${FLG_2}"
      elif [[ ${FLG_1} == "-lv" && ${STACK_LOG_VERBOSE} == 1 ]]; then
        echo ">>>> ${FLG_2}"
      elif [[ ${FLG_1} == "-lvs" && ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
        echo ">>>>>>> ${FLG_2}"
      fi
    fi
  elif [[ ${FLG_1} != "" ]]; then
    echo ${FLG_1}
  fi
}

function logStart()
{
  log -lvs "call ${1}"
  log -lvs ".    - started: ${1}"
}

function logMethod()
{
  log -lvs ".    - info: ${1}"
}

function logFinished()
{
  log -lvs "call ${1}"
  if [[ ${2} != "" ]]; then
    log -lvs ".    - message: ${2}"
  fi
  log -lvs ".    - finished: ${1}"
}

function runSource()
{
  RUN_FILE=${1}
  RUN_IDENT=${2}
  if [[ ${RUN_IDENT} == "" ]]; then
    RUN_IDENT=0
  fi

  RUN_CHARS="."
  if [[ ${RUN_IDENT} > 0 ]]; then
    RUN_CHARS=
    for i in {1..${RUN_IDENT}}
    do
      RUN_CHARS="${RUN_CHARS}....."
    done
    RUN_CHARS="${RUN_CHARS}-"
  fi

  log -lvs "${RUN_CHARS}call runSource:"
  log -lvs "${RUN_CHARS}    - target: ${RUN_FILE} "
  if [[ ${RUN_FILE} == "" ]]; then
    log -lvs "${RUN_CHARS}    - error: empty"
  elif ! [[ -f ${RUN_FILE} ]]; then
    log -lvs "${RUN_CHARS}    - error: not found"
  else
    log -lvs "${RUN_CHARS}    - result: success"
    chmod +x ${RUN_FILE}
    if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
      source ${RUN_FILE}
    else
      echo $(source ${RUN_FILE})&>/dev/null
    fi
  fi
}

function cdDir()
{
  NEW_DIR=${1}
  OLD_DIR=${PWD}
  log -lvs "call cdDir:"
  log -lvs ".    - of: ${OLD_DIR} "
  log -lvs ".    - to: ${NEW_DIR}"
  if ! [[ -d ${NEW_DIR} ]]; then
    log -lvs ".    - result: invalid dir: ${NEW_DIR}"
    return 0;
  fi
  cd ${NEW_DIR}
  if [[ ${PWD} != ${NEW_DIR} ]]; then
    log -lvs ".    - result: no access dir: ${NEW_DIR}"
    return 0;
  fi
  log -lvs ".    - result: success"
  return 1;
}

function fileExists()
{
  TARGET=${1}
  DIR=${2}
  if [[ ${DIR} == "" ]]; then
    DIR=${PWD}
  fi

  log -lvs "call fileExists:"
  log -lvs ".    - target: ${TARGET} "
  log -lvs ".    - dir ${DIR}"
  FILE=${DIR}/${TARGET}
  if ! [[ -f ${FILE} ]]; then
    log -lvs ".    - error: file not found, fileName: ${FILE}"
    return 0;
  fi
  log -lvs ".    - result: success"
  return 1;
}



function makeDir()
{
  MAKE_DIR=${1}
  MAKE_PERMISSION=${2}

  log -lvs "call makeDir:"
  log -lvs ".    - target: ${MAKE_DIR} "
  log -lvs ".    - permission: ${MAKE_PERMISSION} "


  if [[ ${MAKE_DIR} == "" || ${MAKE_PERMISSION} == "" ]]; then
    MSG="Invalid parameters: MAKE_DIR == ${MAKE_DIR}, MAKE_PERMISSION == ${MAKE_PERMISSION} "
    log ${MSG}
    log -lvs ".    - error: ${MSG} "
    return;
  fi

  if [[ ${MAKE_DIR} == "" ]]; then
    MSG="dir is empty"
    log ${MSG}
    log -lvs ".    - error: ${MSG} "
    return;
  fi

  if ! [[ -d ${MAKE_DIR}  ]]; then
    mkdir -p ${MAKE_DIR}
    if ! [[ -d ${MAKE_DIR}  ]]; then
      log -lvs ".    - error: no create dir: ${MSG} "
      return 0
    fi
  fi  


  if [[ ${MAKE_PERMISSION} != "" ]]; then
    chmod ${MAKE_PERMISSION} ${MAKE_DIR};
  fi

  log -lvs ".    - result: success"
  return 1;
}

function copyFile()
{
  SRC=$1
  DST=$2

  log -lvs "call copyFile:"
  log -lvs ".    - target: ${SRC}"
  log -lvs ".    - destine: ${DST}"

  log -lv "Copying ${SRC} to ${DST}"
  if [[ -f ${SRC} ]]; then
    MSG="sources does not exists [${SRC}]"
    log ${MSG}
    log -lvs ".    - error: ${MSG} "
  elif [[ -f ${DST} ]]; then
    MSG="destine exists [${DST}]"
    log ${MSG}
    log -lvs ".    - error: ${MSG} "
  else
    cp -r ${SRC} ${DST}
    if [[ -f ${DST} ]]; then
      log -lvs ".    - result: success"
    fi
  fi
}

function copyFileIfNotExists(){
  SRC=$1
  DST=$2

  log -lvs "call copyFile:"
  log -lvs ".    - target: ${SRC}"
  log -lvs ".    - destine: ${DST}"

  log -lv "Copying ${SRC} to ${DST}"
  if ! [[ -f ${SRC} ]]; then
    MSG="source does not exists [${SRC}]"
    log ${MSG}
    log -lvs ".    - error: ${MSG} "
  else
    if [[ -d ${DST} ]]; then
      rm -rf ${DST}
      log -lvs ".    - remove: ${DST}"
    fi
    cp -r ${SRC} ${DST}
    if [[ -d ${DST} ]]; then
      log -lvs ".    - result: success"
    fi
  fi
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
}

function envsParserFile()
{
  FILE=$1
  if ! [[ -f ${FILE} ]]; then
    return 0;
  else
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

    log -lvs "replace envs in ${FILE}"
    for ENV in "${ENVSLIST[@]}"
    do
      if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
        log -lvs "ENV=${ENV}"
      fi
      ENV=(${ENV//=/ })
      replace="\${${ENV[0]}}"
      replacewith=${ENV[1]}
      if [[ ${replace} == "" || ${replace} == "_" || ${replacewith} == ""  ]]; then
        continue;
      fi

      log -lvs "s/${replace}/${replacewith}/"
      FILE_BACK=${FILE}-sed.bak
      rm -rf ${FILE_BACK}
      cp -r ${FILE} ${FILE_BACK}
      echo $(sed -i "s/${replace}/${replacewith}/g" ${FILE})&>/dev/null
    done
    #cat $FILE;
    return 1;
  fi
}


function envsParserDir()
{
  export DIR=$1
  export EXT=$2

  if [[ ${DIR} == "" || ${EXT} == "" ]]; then
    return 0;
  fi

  if ! [[ -d ${DIR} ]]; then
    return 0;
  fi

  log -lv "parser dir: ${DIR}"
  FILELIST=($(find ${DIR} -name ${EXT}))
  for FILE in "${FILELIST[@]}"
  do
    if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
      log -lv "parser file: ${FILE}"
    fi
    envsParserFile ${FILE}
  done
  return 1;
}