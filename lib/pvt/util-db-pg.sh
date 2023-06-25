#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${INSTALLER_DIR}/lib/pvt/util-db-lib.sh

#postgres
export POSTGRES_PGPASS=${HOME}/.pgpass

function __private_pg_envs_clear()
{
  export POSTGRES_HOST="localhost"
  export POSTGRES_USER=postgres
  export POSTGRES_PASS=postgres
  export POSTGRES_DB=postgres
  export POSTGRES_PORT=5432
}

function __private_pg_envs_check()
{
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi

  if [[ ${POSTGRES_HOST} == "" ]]; then
    export POSTGRES_HOST="localhost"
  fi
  if [[ ${POSTGRES_USER} == "" ]]; then
    export POSTGRES_USER=postgres
  fi
  if [[ ${POSTGRES_PASS} == "" ]]; then
    export POSTGRES_PASS=postgres
  fi
  if [[ ${POSTGRES_DB} == "" ]]; then
    export POSTGRES_DB=postgres
  fi
  if [[ ${POSTGRES_PORT} == "" ]]; then
    export POSTGRES_PORT=5432
  fi

  if [[ ${POSTGRES_HOST} == "" ]]; then 
    echo "Invalid env: POSTGRES_HOST=${POSTGRES_HOST}"
    return 0
  fi
  if [[ ${POSTGRES_USER} == "" ]]; then 
    echo "Invalid env: POSTGRES_USER=${POSTGRES_USER}"
    return 0
  fi
  if [[ ${POSTGRES_PASS} == "" ]]; then 
    echo "Invalid env: POSTGRES_PASS=${POSTGRES_PASS}"
    return 0
  fi
  if [[ ${POSTGRES_DB} == "" ]]; then 
    echo "Invalid env: POSTGRES_DB=${POSTGRES_DB}"
    return 0
  fi
  if [[ ${POSTGRES_PORT} == "" ]]; then 
    echo "Invalid env: POSTGRES_PORT=${POSTGRES_PORT}"
    return 0
  fi
  return 1
}

function __private_pg_pass_apply()
{
  __private_pg_envs_check
  if ! [ "$?" -eq 1 ]; then
      return 0;       
  fi
  AUTH="${POSTGRES_HOST}:${POSTGRES_PORT}:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASS}">${POSTGRES_PGPASS}
  if [[ -f ${POSTGRES_PGPASS} ]];then
      echo ${AUTH} >> ${POSTGRES_PGPASS}
  else
      echo ${AUTH} > ${POSTGRES_PGPASS}
  fi
  chmod 0600 ${POSTGRES_PGPASS};
  return 1
}

function __private_pg_exec_sql()
{
  logStart ${1} "__private_pg_exec_sql"
  EXEC_FILES=(${2})

  for EXEC_FILE in ${EXEC_FILES[*]};
  do
    echo "set client_min_messages to WARNING; ">${DB_DDL_FILE_TMP};
    cat ${EXEC_FILE} >> ${DB_DDL_FILE_TMP};
    __private_db_cleanup_sql ${EXEC_FILES}
    CMD="psql -q -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${POSTGRES_DB} -a -f ${DB_DDL_FILE_TMP}"
    echo $(${CMD})&>/dev/null
    logCommand "$(incInt ${idx})" "filename: ${EXEC_FILE}"
    logCommand "$(incInt ${idx})" "${CMD}"
  done
  logStart ${1} "__private_pg_exec_sql"
  return 1
}

function __private_pg_exec_start()
{
  export DB_ROOT_DIR=${2}
  export POSTGRES_HOST=${3}
  export POSTGRES_USER=${4}
  export POSTGRES_PASS=${5}
  export POSTGRES_DB=${6}
  export POSTGRES_PORT=${7}

  __private_db_envs_prepare ${DB_ROOT_DIR}
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  __private_pg_pass_apply
  if ! [ "$?" -eq 1 ]; then
      return 0;       
  fi
  return 1
}

function __private_pg_exec_finish()
{
  __private_db_envs_clear
  __private_pg_envs_clear
}


function __private_pg_exec_script()
{
  idx=$(toInt ${1})
  logStart ${idx} "__private_pg_exec_script"
  __private_pg_exec_start "$@"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi

  DDL_FILE=$(__private_db_ddl_apply_scan ${DB_ROOT_DIR})
  __private_pg_exec_sql "$(incInt ${idx})" "${DDL_FILE}"
  if ! [ "$?" -eq 1 ]; then
    logError "$(incInt ${idx})" "fail: __private_pg_exec_sql"
    return 0;       
  fi

  __private_pg_exec_finish
  logFinished ${idx} "__private_pg_exec_script"
  return 1
}

function __private_pg_exec_ddl()
{
  idx=$(toInt ${1})
  logStart ${idx} "__private_pg_exec_ddl"
  __private_pg_exec_start "$@"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi

  DDL_FILE=$(__private_db_ddl_maker ${DB_ROOT_DIR})
  __private_pg_exec_sql "$(incInt ${idx})" "${DDL_FILE}"
  if ! [ "$?" -eq 1 ]; then
    logError "$(incInt ${idx})" "fail: __private_pg_exec_sql"
    return 0;       
  fi

  __private_pg_exec_finish
  logFinished ${1} "__private_pg_exec_ddl"
  return 1
}

__private_pg_exec_finish