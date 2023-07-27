#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${INSTALLER_DIR}/lib/util-build.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh
. ${INSTALLER_DIR}/lib/util-db.sh

function deployPG()
{
  PG_DIR=${2}
  PG_HOST=${APPLICATION_DB_HOST}
  PG_USER=${APPLICATION_DB_USER}
  PG_PASS=${APPLICATION_DB_PASSWORD}
  PG_DB=${APPLICATION_DB_DATABASE}
  PG_PORT=${APPLICATION_DB_PORT}    
  echo "dbPGExecScript ${1} ${PG_DIR} ${PG_HOST} ${PG_USER} ${PG_PASS} ${PG_DB} ${PG_PORT}"
  dbPGExecScript ${1} ${PG_DIR} ${PG_HOST} ${PG_USER} ${PG_PASS} ${PG_DB} ${PG_PORT}
  return 1
}

function deployDb()
{
  idx=$(toInt ${1})
  logStart ${idx} "deployDb"
 

  if [[ ${2} != "" && ${3} != "" ]]; then
    export STACK_ACTION=${2}
    export STACK_PROJECT=${3}
  fi

  prepareStack "$(incInt ${idx})" ${STACK_ACTION} ${STACK_PROJECT}

  if [[ ${APPLICATION_DB_TYPE} == "postgres" ]]; then
    deployPG "$(incInt ${idx})" ${STACK_APPLICATIONS_DATA_DB_DIR}/${STACK_PROJECT}
  else
    logError "$(incInt ${idx})" "Invalid database driver, APPLICATION_DB_TYPE:[${APPLICATION_DB_TYPE}]"
  fi

  logFinished ${idx} "deployDb"
}

 