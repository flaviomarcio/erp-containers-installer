#!/bin/bash -e



. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-stack.sh
. ${INSTALLER_LIB}/pvt/lib-auth.sh


function __privateEnvsInstallerDir()
{
  stackEnvsClearByStack
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling stackEnvsClearByStack, ${__func_return}"
    return 0
  fi
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
  export STACK_INSTALLER_DOCKER_DIR=${INSTALLER_DIR}/docker
  export STACK_INSTALLER_DOCKER_CONF_DIR=${STACK_INSTALLER_DOCKER_DIR}/conf
  export STACK_INSTALLER_DOCKER_FILE_DIR=${STACK_INSTALLER_DOCKER_DIR}/dockerfiles
  export STACK_INSTALLER_DOCKER_COMPOSE_DIR=${STACK_INSTALLER_DOCKER_DIR}/compose
  return 1
}

function utilPrepareInit()
{
  __utilPrepareInit_stack_environment=${1}
  __utilPrepareInit_stack_target=${2}
  
  stackEnvsLoad "${__utilPrepareInit_stack_environment}" "${__utilPrepareInit_stack_target}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackEnvsLoad, ${__func_return}"
    return 0;
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
  __prepareStackForDeploy_project=${1}

  stackEnvsLoadByStack "${STACK_ENVIRONMENT}" "${STACK_TARGET}" "${__prepareStackForDeploy_project}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackEnvsLoadByStack, ${__func_return}"
    return 0;
  fi

  if [[ ${STACK_SERVICE_STORAGE_DATA_DIR} == "" ]]; then
    export __func_return="invalid env \${STACK_SERVICE_STORAGE_DATA_DIR}"
    return 0
  elif ! [[ -d ${STACK_SERVICE_STORAGE_DATA_DIR} ]]; then
    export __func_return="invalid dir, env \${STACK_SERVICE_STORAGE_DATA_DIR}: ${STACK_SERVICE_STORAGE_DATA_DIR}"
    return 0
  elif [[ ${STACK_SERVICE_STORAGE_BACKUP_DIR} == "" ]]; then
    export __func_return="invalid env \${STACK_SERVICE_STORAGE_BACKUP_DIR}"
    return 0
  elif ! [[ -d ${STACK_SERVICE_STORAGE_BACKUP_DIR} ]]; then
    export __func_return="invalid env \${STACK_SERVICE_STORAGE_BACKUP_DIR}: ${STACK_SERVICE_STORAGE_BACKUP_DIR}"
    return 0
  fi

  envsSetIfIsEmpty APPLICATION_NAME ${__prepareStackForDeploy_project}
  envsSetIfIsEmpty APPLICATION_DEPLOY_PORT 8080
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS ${STACK_SERVICE_HOSTNAME}
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_PATH "/"
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_PUBLIC "${STACK_SERVICE_HOSTNAME}.${STACK_DOMAIN}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_PUBLIC_PATH "${APPLICATION_DEPLOY_DNS_PATH}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_3RDPARTY "${STACK_SERVICE_HOSTNAME}.${STACK_DOMAIN}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_3RDPARTY_PATH "${APPLICATION_DEPLOY_DNS_PATH}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_IMAGE "${STACK_IMAGE_NAME_URL}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_HOSTNAME ${STACK_SERVICE_HOSTNAME}
  envsSetIfIsEmpty APPLICATION_DEPLOY_MODE replicated
  envsSetIfIsEmpty APPLICATION_DEPLOY_NODE "${STACK_SERVICE_NODE_SERVICES}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_REPLICAS "1"
  envsSetIfIsEmpty APPLICATION_DEPLOY_NETWORK_NAME ${STACK_NETWORK_DEFAULT}
  envsSetIfIsEmpty APPLICATION_DEPLOY_DATA_DIR "${STACK_SERVICE_STORAGE_DATA_DIR}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_BACKUP_DIR "${STACK_SERVICE_STORAGE_BACKUP_DIR}"

  stackMkDir 755 "${STACK_SERVICE_STORAGE_DATA_DIR} ${STACK_SERVICE_STORAGE_BACKUP_DIR}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling prepareStackForDeploy::stackMkDir: ${__func_return}"
    return 0;
  fi

  return 1

}


# function __util_prepare_test()
# {
#   return 1
# }

# __util_prepare_test