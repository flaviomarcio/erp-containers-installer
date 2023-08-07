#!/bin/bash -e

. ${BASH_BIN}/lib-strings.sh

function __privateEnvsStackEnvInit()
{
  export __func_return=
  if ! [[ -f ${PUBLIC_STACK_ENVS_FILE} ]]; then
    export __func_return="File not found ${PUBLIC_STACK_ENVS_FILE}"
    return 0
  fi

  source ${PUBLIC_STACK_ENVS_FILE}

  envsSetIfIsEmpty STACK_SERVICE_NODE_DB "node.role == manager"
  envsSetIfIsEmpty STACK_SERVICE_NODE_GLOBAL "${STACK_SERVICE_NODE_DB}"
  envsSetIfIsEmpty STACK_SERVICE_NODE_SERVICES "${STACK_SERVICE_NODE_DB}"

  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_USER services
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_PASS services

  envsSetIfIsEmpty POSTGRES_DATABASE "services"
  envsSetIfIsEmpty POSTGRES_HOST "localhost"
  envsSetIfIsEmpty POSTGRES_USER "${STACK_SERVICE_DEFAULT_USER}"
  envsSetIfIsEmpty POSTGRES_PASSWORD "${STACK_SERVICE_DEFAULT_PASS}"
  envsSetIfIsEmpty POSTGRES_PORT 5432
  envsSetIfIsEmpty POSTGRES_URL "jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DATABASE}"

  return 1
}

function __privateEnvsIsInited()
{
  export __func_return=
  if [[ ${PUBLIC_STACK_TARGETS_FILE} == "" ]]; then
    export __func_return="Invalid env \${PUBLIC_STACK_TARGETS_FILE}"
    return 0
  fi

  if ! [[ -f ${PUBLIC_STACK_TARGETS_FILE} ]]; then
    export __func_return="Invalid targets file: ${PUBLIC_STACK_TARGETS_FILE}"
    return 0
  fi

  if [[ ${PUBLIC_STACK_ENVS_FILE} == "" ]]; then
    export __func_return="Invalid env \${PUBLIC_STACK_ENVS_FILE}"
    return 0
  fi

  if ! [[ -f ${PUBLIC_STACK_ENVS_FILE} ]]; then
    export __func_return="Invalid stack environment file: ${PUBLIC_STACK_ENVS_FILE}"
    return 0
  fi

  return 1
}

function __privateEnvsStackClear()
{
  export APPLICATION_STACK=
  export APPLICATION_NAME=
  export APPLICATION_GIT=
  export APPLICATION_GIT_BRANCH=
  export APPLICATION_DEPLOY_PORT=
  export APPLICATION_DEPLOY_DNS=
  export APPLICATION_DEPLOY_DNS_PUBLIC=
  export APPLICATION_DEPLOY_IMAGE=
  export APPLICATION_DEPLOY_HOSTNAME=
  export APPLICATION_DEPLOY_NODE=
  export APPLICATION_DEPLOY_MODE=
  export APPLICATION_DEPLOY_REPLICAS=
  export APPLICATION_DEPLOY_DATA_DIR=
  export APPLICATION_DEPLOY_BACKUP_DIR=
  export APPLICATION_DEPLOY_NETWORK_NAME=
  return 1
}

function __privateEnvsPrepare()
{    
  export PUBLIC_STORAGE_DIR=$(realpath ${PUBLIC_APPLICATIONS_DIR}/storage)
  export PUBLIC_LIB_DIR=$(realpath ${PUBLIC_APPLICATIONS_DIR}/lib)
  return 1
}

function __privateEnvsStartedInit()
{
  envsSetIfIsEmpty STACK_ROOT_DIR ${HOME}

  export PUBLIC_APPLICATIONS_DIR=${STACK_ROOT_DIR}/applications
  export PUBLIC_STACK_TARGET_DIR=${PUBLIC_APPLICATIONS_DIR}/${STACK_ENVIRONMENT}/${STACK_TARGET}
  export PUBLIC_ENVS_DIR=${PUBLIC_APPLICATIONS_DIR}/${STACK_ENVIRONMENT}/envs

  #env configurations
  export PUBLIC_STACK_TARGETS_FILE=${PUBLIC_APPLICATIONS_DIR}/stack_targets.env
  export PUBLIC_STACK_ENVS_FILE=${PUBLIC_STACK_TARGET_DIR}/stack_envs.env
  return 1
}

function __privateEnvsPublic()
{
  __privateEnvsIsInited
  if ! [ "$?" -eq 1 ]; then
    echFail 1 "fail on calling __privateEnvsIsInited: ${__func_return}"
    return 0
  fi

  __privateEnvsStackEnvInit
  if ! [ "$?" -eq 1 ]; then
    echFail 1 "fail on calling __privateEnvsStackEnvInit: ${__func_return}"
    return 0
  fi

  envsSetIfIsEmpty STACK_DOMAIN localhost
  envsSetIfIsEmpty STACK_TEMPLATES_DIR "${PUBLIC_STACK_TARGET_DIR}/templates"

  return 1
}

function __privateEnvsAuthService()
{
  envsSetIfIsEmpty STACK_SERVICE_AUTH_SERVER_CERT ${STACK_SERVICE_AUTH_SERVER_CERT}
  return 1
}

function __privateEnvsResources()
{
  envsSetIfIsEmpty STACK_CPU_DEFAULT 1
  envsSetIfIsEmpty STACK_MEMORY_DEFAULT "1GB"
  envsSetIfIsEmpty STACK_DEPLOY_REPLICAS 1
  return 1
}

function __privateEnvsTargetFinal()
{
  export STACK_NETWORK_INBOUND=${STACK_PREFIX}-inbound
  export STACK_REGISTRY_DNS=${STACK_PREFIX}-registry:5000
  export STACK_REGISTRY_DNS_PUBLIC=${STACK_PREFIX}-registry.${STACK_DOMAIN}:5000
  return 1
}

function __privateEnvsInstallerDir()
{
  #APPLICATIONS DIR
  export STACK_APPLICATIONS_DIR=${ROOT_DIR}/applications
  export STACK_APPLICATIONS_PROJECT_DIR=${STACK_APPLICATIONS_DIR}/projects
  export STACK_APPLICATIONS_DATA_DIR=${STACK_APPLICATIONS_DIR}/data
  export STACK_APPLICATIONS_DATA_ENV_DIR=${STACK_APPLICATIONS_DATA_DIR}/envs
  export STACK_APPLICATIONS_DATA_ENV_JSON_FILE=${STACK_APPLICATIONS_DATA_ENV_DIR}/env_file_default.json
  export STACK_APPLICATIONS_DATA_CONF_DIR=${STACK_APPLICATIONS_DATA_DIR}/conf
  export STACK_APPLICATIONS_DATA_SRC_DIR=${STACK_APPLICATIONS_DATA_DIR}/source
  export STACK_APPLICATIONS_DATA_DB_DIR=${STACK_APPLICATIONS_DATA_DIR}/db

  #INSTALLER DIR
  export STACK_INSTALLER_BIN_DIR=${INSTALLER_DIR}/bin
  export STACK_INSTALLER_LIB_DIR=${INSTALLER_DIR}/lib
  export STACK_INSTALLER_DOCKER_DIR=${INSTALLER_DIR}/docker
  export STACK_INSTALLER_DOCKER_CONF_DIR=${STACK_INSTALLER_DOCKER_DIR}/conf
  export STACK_INSTALLER_DOCKER_FILE_DIR=${STACK_INSTALLER_DOCKER_DIR}/dockerfiles
  export STACK_INSTALLER_DOCKER_COMPOSE_DIR=${STACK_INSTALLER_DOCKER_DIR}/compose
  return 1
}

function utilPrepareInit()
{
  __privateEnvsStartedInit
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __privateEnvsStartedInit"
    return 0
  fi
  __privateEnvsIsInited
  if ! [ "$?" -eq 1 ]; then
    echFail 1 "fail on calling __privateEnvsIsInited: ${__func_return}"
    return 0
  fi
  __privateEnvsStackClear
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __privateEnvsStackClear"
    return 0
  fi
  __privateEnvsPrepare
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __privateEnvsPrepare"
    return 0
  fi
  __privateEnvsPublic
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __privateEnvsPublic"
    return 0
  fi
  __privateEnvsAuthService
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __privateEnvsAuthService"
    return 0
  fi
  __privateEnvsResources
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __privateEnvsResources"
    return 0
  fi
  __privateEnvsTargetFinal
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __privateEnvsTargetFinal"
    return 0
  fi
  __privateEnvsInstallerDir
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __privateEnvsInstallerDir"
    return 0
  fi
  return 1
}

function prepareStackForDeploy()
{
  __prepareStackForDeploy_prefix=${1}
  __prepareStackForDeploy_project=${2}
  __prepareStackForDeploy_domain=${3}
  __prepareStack_prefix_name="${__prepareStackForDeploy_prefix}-${__prepareStackForDeploy_project}"
  envsSetIfIsEmpty APPLICATION_NAME ${__prepareStackForDeploy_project}
  envsSetIfIsEmpty APPLICATION_DEPLOY_PORT 8080
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS ${__prepareStack_prefix_name}
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_PUBLIC "${__prepareStack_prefix_name}.${__prepareStackForDeploy_domain}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_IMAGE "${STACK_REGISTRY_DNS_PUBLIC}/${__prepareStack_prefix_name}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_HOSTNAME ${__prepareStack_prefix_name}
  envsSetIfIsEmpty APPLICATION_DEPLOY_MODE replicated
  envsSetIfIsEmpty APPLICATION_DEPLOY_NODE "${STACK_SERVICE_NODE_SERVICES}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_REPLICAS "1"
  envsSetIfIsEmpty APPLICATION_DEPLOY_NETWORK_NAME ${STACK_NETWORK_INBOUND}
  envsSetIfIsEmpty APPLICATION_DEPLOY_TEMPLATE_DIR "${STACK_TEMPLATES_DIR}/${__prepareStackForDeploy_prefix}/${__prepareStackForDeploy_project}/data"
  envsSetIfIsEmpty APPLICATION_DEPLOY_DATA_DIR "${PUBLIC_STORAGE_DIR}/${__prepareStackForDeploy_prefix}/${__prepareStackForDeploy_project}/data"
  envsSetIfIsEmpty APPLICATION_DEPLOY_BACKUP_DIR "${PUBLIC_STORAGE_DIR}/${__prepareStackForDeploy_prefix}/${__prepareStackForDeploy_project}/backup"

  if ! [[ -d ${APPLICATION_DEPLOY_TEMPLATE_DIR} ]]; then
    mkdir -p ${APPLICATION_DEPLOY_TEMPLATE_DIR}
    chmod 777 ${APPLICATION_DEPLOY_TEMPLATE_DIR}
  fi
  if ! [[ -d ${APPLICATION_DEPLOY_DATA_DIR} ]]; then
    mkdir -p ${APPLICATION_DEPLOY_DATA_DIR}
    chmod 777 ${APPLICATION_DEPLOY_DATA_DIR}
  fi
  if ! [[ -d ${APPLICATION_DEPLOY_BACKUP_DIR} ]]; then
    mkdir -p ${APPLICATION_DEPLOY_BACKUP_DIR}
    chmod 777 ${APPLICATION_DEPLOY_BACKUP_DIR}
  fi

  return 1

}
