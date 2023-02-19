#!/bin/bash

function log()
{
  FLG_1=$1
  FLG_2=$2
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

function runSource()
{
  RUN_FILE=$1
  if [[ ${RUN_FILE} == "" ]]; then
    log -lv ">>>> empty ${RUN_FILE}"
  elif ! [[ -f ${RUN_FILE} ]]; then
    log -lv ">>>> source[${RUN_FILE}] invalid"
  else
    log -lv ">>>> source ${RUN_FILE}"
    chmod +x ${RUN_FILE}
    if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
      source ${RUN_FILE}
    else
      echo $(source ${RUN_FILE})&>/dev/null
    fi
  fi
}

function makeDir()
{
  MAKE_DIR=${1}
  MAKE_PARAM=${2}

  log -l "Making dir [${MAKE_DIR}]"
  if [[ ${MAKE_DIR} == "" ]]; then
    log -lvs ">>>> dir is empty"
    return;
  fi
  if [[ -d ${MAKE_DIR}  ]]; then
    log -lvs ">>>> dir exists [${MAKE_DIR}]"
    return;
  fi
  
  log -lvs ">>>> mkdir -p ${MAKE_DIR}"
  echo $(mkdir -p ${MAKE_DIR})&>/dev/null

  if [[ ${MAKE_PARAM} != "" ]]; then
    log -lvs ">>>> chmod ${MAKE_PARAM} ${MAKE_DIR}"
    echo $(chmod ${MAKE_PARAM} ${MAKE_DIR})&>/dev/null
  fi
}

function copyFile(){
  SRC=$1
  DST=$2

  log -lv "Copying ${SRC} to ${DST}"
  if [[ -f ${SRC} ]]; then
    log -lvs ">>>> sources does not exists [${SRC}]" 
  elif [[ -f ${DST} ]]; then
    log -lvs ">>>> [${DST}] override"
  else
    log -lvs "cp -r ${SRC} ${DST}"
    cp -r ${SRC} ${DST}
  fi
}

function copyFileIfNotExists(){
  SRC=$1
  DST=$2

  log -lv "Copying ${SRC} to ${DST}"
  if ! [[ -f ${SRC} ]]; then
    log -lvs ">>>> sources does not exists [${SRC}]"
  elif [[ -f ${DST} ]]; then
    log -lvs ">>>> destine exists [${DST}]"
  else
    log -lvs ">>>> cp -r ${SRC} ${DST}"
    cp -r ${SRC} ${DST}
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