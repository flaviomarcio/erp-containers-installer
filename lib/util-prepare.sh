#!/bin/bash

. ${PWD}/lib/util.sh

function prepare()
{
    export PUBLIC_APPLICATIONS_DIR=${HOME}/applications
    export PUBLIC_STORAGE_DIR=${PUBLIC_APPLICATIONS_DIR}/storage
    export PUBLIC_LIB_DIR=${PUBLIC_APPLICATIONS_DIR}/lib

    export STACK_DB_DROP=0
    export STACK_DOMAIN=portela-professional.com.br
    export STACK_ENVIRONMENT_FILE=${PUBLIC_APPLICATIONS_DIR}/stack_envs
}

function prepareEnvsPublic()
{
    if ! [[ -f ${STACK_ENVIRONMENT_FILE} ]]; then
        log "Invalid public env: ${STACK_ENVIRONMENT_FILE}"
        return;
    fi
    source ${STACK_ENVIRONMENT_FILE}
}

function prepareEnvsDefault()
{

    if [[ ${ROOT_DIR} == "" ]]; then
        export ROOT_DIR=${PWD}
    fi

    if [[ ${QT_VERSION} == "" ]]; then
        export QT_VERSION=6.4.2
    fi

    if [[ ${STACK_BIN_DIR} == "" ]]; then
        export STACK_BIN_DIR=${ROOT_DIR}/bin
    fi

    if [[ ${STACK_APPLICATIONS_DIR} == "" ]]; then
        export STACK_APPLICATIONS_DIR=${ROOT_DIR}/applications
    fi

    if [[ ${STACK_CPU_DEFAULT} == "" ]]; then
        export STACK_CPU_DEFAULT=1
    fi

    if [[ ${STACK_MEMORY_DEFAULT} == "" ]]; then
        export STACK_MEMORY_DEFAULT=1GB
    fi

    if [[ ${STACK_DEPLOY_NODE} == "" ]]; then
        export STACK_DEPLOY_NODE="node.role==manager"
    fi

    if [[ ${STACK_DEPLOY_MODE} == "" ]]; then
        export STACK_DEPLOY_MODE=replicated
    fi

    if [[ ${STACK_DEPLOY_REPLICAS} == "" ]]; then
        export STACK_DEPLOY_REPLICAS=1
    fi

    if [[ ${STACK_DEPLOY_VERSION} == "" ]]; then
        export STACK_DEPLOY_VERSION=v1
    fi

    if [[ ${STACK_ENVIRONMENT} == "" ]]; then
        export STACK_ENVIRONMENT=testing
    fi

    if [[ ${STACK_DOMAIN} == "" ]]; then
        export STACK_DNS=localhost
    fi

    if [[ ${STACK_TARGET} == "" ]]; then
        export STACK_TARGET=company
    fi

    if [[ ${STACK_NETWORK_INBOUND} == "" ]]; then
        export STACK_NETWORK_INBOUND=${STACK_ENVIRONMENT}-${STACK_TARGET}-inbound
    fi

    export STACK_DEPLOY_NETWORK=${STACK_NETWORK_INBOUND}

    if [[ ${STACK_REGISTRY_DNS} == "" ]]; then
        export STACK_REGISTRY_DNS=${STACK_ENVIRONMENT}-${STACK_TARGET}-registry.${STACK_DOMAIN}:5000
    fi
}

function prepareEnvsDir()
{
    export STACK_APPLICATION_PROJECT_DIR=${STACK_APPLICATIONS_DIR}/projects
    export STACK_APPLICATION_BIN_DIR=${STACK_APPLICATIONS_DIR}/bin
    export STACK_APPLICATION_DB_DIR=${STACK_APPLICATIONS_DIR}/db
    export STACK_APPLICATION_DATA_DIR=${STACK_APPLICATIONS_DIR}/data
    export STACK_APPLICATION_DOCKEFILE_DIR=${STACK_APPLICATION_DATA_DIR}/dockerfiles
    export STACK_APPLICATION_ENV_DIR=${STACK_APPLICATION_DATA_DIR}/envs
    export STACK_APPLICATION_CONFIG_DIR=${STACK_APPLICATION_DATA_DIR}/conf
    export STACK_APPLICATION_SOURCE_DIR=${STACK_APPLICATION_DATA_DIR}/source
    export STACK_APPLICATION_YML_DIR=${STACK_APPLICATION_DATA_DIR}/yml
    export STACK_RUN_PREPARE_ENVS=${STACK_APPLICATION_BIN_DIR}/run-prepare.env
}


function utilPrepareInit()
{
    prepare
    prepareEnvsPublic
    prepareEnvsDefault
    prepareEnvsDir
}
