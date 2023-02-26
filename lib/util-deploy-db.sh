#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${INSTALLER_DIR}/lib/util-build.sh
. ${INSTALLER_DIR}/lib/util-prepare.sh

function deployPG_prepare()
{
    logFinished ${1} "deployPG_prepare"
    APPLICATION_DB_HOST_FIX=localhost
    ERP_SQL_FILE_SCRIPT_TEMP="/tmp/tmp_scrpt.sql"
    ERP_SQL_FILE_SCRIPT_TEMP_FULL="/tmp/tmp_scrpt-log.sql"

    rm -rf ${ERP_SQL_FILE_SCRIPT_TEMP_FULL};

   
    if [[ ${APPLICATION_DB_HOST} == "" ]]; then 
        log "Invalid env: APPLICATION_DB_HOST=${APPLICATION_DB_HOST}"
        exit 0;
    fi
    if [[ ${APPLICATION_DB_USER} == "" ]]; then 
        log "Invalid env: APPLICATION_DB_USER=${APPLICATION_DB_USER}"
        exit 0;
    fi
    if [[ ${APPLICATION_DB_PASSWORD} == "" ]]; then 
        log "Invalid env: APPLICATION_DB_PASSWORD=${APPLICATION_DB_PASSWORD}"
        exit 0;
    fi
    if [[ ${APPLICATION_DB_DATABASE} == "" ]]; then 
        log "Invalid env: APPLICATION_DB_DATABASE=${APPLICATION_DB_DATABASE}"
        exit 0;
    fi
    if [[ ${APPLICATION_DB_PORT} == "" ]]; then 
        log "Invalid env: APPLICATION_DB_PORT=${APPLICATION_DB_PORT}"
        exit 0;
    fi
    logFinished ${1} "deployPG_prepare"
}

function deployPG_pgpassCheck()
{
    logStart ${1} "deployPG_pgpassCheck"
    POSTGRES_PGPASS=${HOME}/.pgpass
    POSTGRES_SERVER=localhost
    AUTH="${APPLICATION_DB_HOST_FIX}:${APPLICATION_DB_PORT}:${APPLICATION_DB_DATABASE}:${APPLICATION_DB_USER}:${APPLICATION_DB_PASSWORD}">${POSTGRES_PGPASS}
    if [[ -f ${POSTGRES_PGPASS} ]];then
        sed -i "/${AUTH}/d" ${POSTGRES_PGPASS}
        echo ${AUTH} >> ${POSTGRES_PGPASS}
    fi
    chmod 0600 ${POSTGRES_PGPASS};
    logFinished ${1} "deployPG_pgpassCheck"
}


function deployPG_runScripts()
{
    logStart ${1} "deployPG_runScripts"
    SCRIPTS_STEP_DIR=${2}

    for SCRIPT_STEP_FILENAME in "${SCRIPTS_STEP_FILES[@]}"
    do
        FILTER="${SCRIPT_STEP_FILENAME}*.sql"
        log "              Upgrade [${FILTER}] in [./$(basename ${SCRIPTS_STEP_DIR})]";      
        FILELIST=($(find ${SCRIPTS_STEP_DIR} -iname ${FILTER} | sort))
        for FILE in "${FILELIST[@]}"
        do
            FILENAME=$(basename ${FILE})
            DIRNAME=$(dirname ${FILE}) 
            DIRNAME=$(basename ${DIRNAME})
            DIRNAME=$(basename ${DIRNAME})
            log "                  executing [./${DIRNAME}], ${FILENAME} to ${ERP_SQL_FILE_SCRIPT_TEMP}";            
            echo "set client_min_messages to WARNING; ">${ERP_SQL_FILE_SCRIPT_TEMP};
            cat ${FILE} >> ${ERP_SQL_FILE_SCRIPT_TEMP};
            logCommand ${1} "psql -h ${APPLICATION_DB_HOST_FIX} -U ${APPLICATION_DB_USER} -p ${APPLICATION_DB_PORT} -d ${APPLICATION_DB_DATABASE} -a -f ${ERP_SQL_FILE_SCRIPT_TEMP}"
            echo $(psql -h ${APPLICATION_DB_HOST_FIX} -U ${APPLICATION_DB_USER} -p ${APPLICATION_DB_PORT} -d ${APPLICATION_DB_DATABASE} -a -f ${ERP_SQL_FILE_SCRIPT_TEMP})#>/dev/null;
        done
    done
    logFinished ${1} "deployPG_runScripts"
}

function deployPG_paramCheck()
{
    logStart ${1} "deployPG_paramCheck"
    logFinished ${1} "deployPG_paramCheck"
}

function deployPG_scriptScan()
{
    logStart ${1} "deployPG_scriptScan"
    CHECK=$(find ${DEPLOY_DB_PG_DDL_DIR} -iname '*.sql' | sort);
    if [[ ${CHECK} == "" ]]; then
        echo $'\n'"      UpdateDB No files SQL: ${DEPLOY_DB_PG_DDL_DIR}";
        return 1;
    fi

    cd $ERP_ROOT;
    echo $'\n'"      UpdateDB upgrade steps";
    echo $'\n'"         UpdateDB erp-services-database step 1";

    SCRIPTS_STEP_DIR=${DEPLOY_DB_PG_DDL_DIR_SERVICE}
    SCRIPTS_STEP_FILES=(schemas databases)
    deployPG_runScripts ${1} ${DEPLOY_DB_PG_DDL_DIR}

    echo $'\n'"         UpdateDB erp-database";
    SCRIPTS_STEP_DIR=${DEPLOY_DB_PG_DDL_DIR}
    SCRIPTS_STEP_FILES=(schemas tables constraints view_00 view_01 view_02 view_03 indexes dblink initdata fakedata fakedata)
    deployPG_runScripts ${1} ${SCRIPTS_STEP_DIR}


    echo $'\n'"         UpdateDB erp-database";
    SCRIPTS_STEP_DIR=${DEPLOY_DB_PG_DDL_DIR}
    SCRIPTS_STEP_FILES=(maintenance)
    deployPG_runScripts ${1} ${SCRIPTS_STEP_DIR}
    logFinished ${1} "deployPG_scriptScan"
}

function deployPG()
{
    idt="$(incInt ${1})"
    export DEPLOY_DB_PG_DDL_DIR=${2}
    deployPG_prepare ${idt}
    deployPG_pgpassCheck ${idt}
    deployPG_paramCheck ${idt}
    deployPG_scriptScan ${idt}
    return 1
}

function deployDb()
{
  logStart ${1} "deployDb"
  if [[ ${2} != "" && ${3} != "" ]]; then
    export STACK_ACTION=${2}
    export STACK_PROJECT=${3}
  fi

  buildProjectPrepare "$(incInt ${1})" ${STACK_ACTION} ${STACK_PROJECT}

  DIR=${STACK_APPLICATIONS_DATA_DB_DIR}/${STACK_PROJECT}
    if ! [[ -d ${DIR} ]]; then
      logError ${1} "Invalid ddl db:${DIR}"
      return 0;
  fi

  if [[ ${APPLICATION_DB_DRIVER} == "postgres" ]]; then
    deployPG ${1} ${DIR}
  else
    logError ${1} "Invalid database driver, APPLICATION_DB_DRIVER:[${APPLICATION_DB_DRIVER}]"
  fi

  logFinished ${1} "deployDb"
}

 