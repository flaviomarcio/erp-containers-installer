#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${INSTALLER_DIR}/lib/pvt/util-db-pg.sh

function dbPGExecScript()
{
  idx=$(toInt ${1})
  logStart ${idx} "dbPGExecScript"
  __private_pg_exec_script "$@"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  logFinished ${idx} "dbPGExecScript"
  return 1
}

function dbPGExecDDL()
{
  idx=$(toInt ${1})
  logStart ${idx} "dbPGExecDDL"
  __private_pg_exec_ddl "$@"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  logFinished ${idx} "dbPGExecDDL"
  return 1
}

# __private_pg_exec_finish

# cd ..
# cd ..

# ROOT_DIR=${PWD}/applications/data/db/pg
# PG_HOST="localhost"
# PG_USER=services
# PG_PASS=ZjU0ODUyMjVi
# PG_DB=services
# PG_PORT=5432

# echo "--------------------------------------"
# echo "ROOT_DIR == ${ROOT_DIR}"
# echo "PG_HOST == ${PG_HOST}"
# echo "PG_USER == ${PG_USER}"
# echo "PG_PASS == ${PG_PASS}"
# echo "PG_DB == ${PG_DB}"
# echo "PG_PORT == ${PG_PORT}"
# echo "--------------------------------------"

# logVerboseSet
# dbPGExecScript ${ROOT_DIR} ${PG_HOST} ${PG_USER} ${PG_PASS} ${PG_DB} ${PG_PORT} 