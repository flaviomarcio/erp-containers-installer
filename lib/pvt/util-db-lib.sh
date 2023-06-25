#!/bin/bash

. ${BASH_BIN}/bash-util.sh

export DB_ROOT_DIR=
export DB_DDL_FILE="/tmp/ddl_init_db.sql"
export DB_DDL_FILE_TMP="/tmp/ddl_file.sql"

function __private_db_envs_clear()
{
  if [[ -f ${DB_DDL_FILE_TMP} ]]; then
    rm -rf ${DB_DDL_FILE_TMP};
  fi 
  export DB_ROOT_DIR=
}

function __private_db_envs_check()
{
  if ! [[ -d ${DB_ROOT_DIR} ]]; then
      echo "Invalid db root dir:${DB_ROOT_DIR}"
      return 0
  fi
  return 1
}

function __private_db_envs_prepare()
{
  export DB_ROOT_DIR=${1}
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  return 1
}

function __private_db_cleanup_sql()
{
  CLEANUP_FILE=${1}
  if ! [[ -f ${DDL_FILE} ]]; then
      return 0;
  fi
  RESERVED_LIST=(DROP drop TRUNCATE truncate DELETE delete CASCADE cascade)
  for RESERVED in ${RESERVED_LIST[*]}; do 
      sed -i "/${RESERVED}/d" ${CLEANUP_FILE}
  done
  return 1;
}

function __private_db_scan_files()
{
  DB_SCAN_RETURN=
  DB_SCAN_DIR=${1}
  DB_SCAN_FILTERS=(tables constraints indexes initdata view)
  for DB_SCAN_FILTER in ${DB_SCAN_FILTERS[*]}; do 
    DB_SCAN_FILTER="${DB_SCAN_FILTER}*.sql"
    DB_SCAN_FILES=($(echo $(find ${DB_SCAN_DIR} -iname ${DB_SCAN_FILTER} | sort)))
    for DB_SCAN_FILE in ${DB_SCAN_FILES[*]};
    do
      DB_SCAN_RETURN="${DB_SCAN_RETURN} ${DB_SCAN_FILE}"
    done
  done
  echo ${DB_SCAN_RETURN}
  return 1
}

function __private_db_ddl_maker()
{
  DDL_MAKE_FILES=($(__private_db_scan_files "${1}"))
  echo "">${DB_DDL_FILE}
  for DDL_MAKE_FILE in ${DDL_MAKE_FILES[*]};
  do
    cat ${DDL_MAKE_FILE} >> ${DB_DDL_FILE}
  done
  echo ${DB_DDL_FILE}
  return 1
}

function __private_db_ddl_apply_scan()
{
  DDL_SCAN_FILES=($(__private_db_scan_files "${1}"))
  for DDL_SCAN_FILE in ${DDL_SCAN_FILES[*]};
  do    
    DDL_SCAN_DIR_FILES="${DDL_SCAN_DIR_FILES} ${DDL_SCAN_FILE}"
  done
  echo ${DDL_SCAN_DIR_FILES}
  return 1
}