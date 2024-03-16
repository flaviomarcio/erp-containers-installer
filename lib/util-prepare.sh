#!/bin/bash -e

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-stack.sh
. ${INSTALLER_LIB}/pvt/lib-auth.sh


function __privateEnvsDNSList()
{
  export __func_return=
  if [[ ${STACK_APPLICATIONS_PROJECT_DIR} == "" ]]; then
    export __func_return="invalid env \${STACK_APPLICATIONS_PROJECT_DIR}"
    return 0
  fi

  if ! [[ -d ${STACK_APPLICATIONS_PROJECT_DIR} ]]; then
    export __func_return="invalid env \${STACK_APPLICATIONS_PROJECT_DIR} : ${STACK_APPLICATIONS_PROJECT_DIR}"
    return 0
  fi

  export STACK_DNS_LIST=$(ls ${STACK_APPLICATIONS_PROJECT_DIR})
  return 1
}

function __privateEnvsInstallerDir()
{
  stackEnvsClearByStack
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling stackEnvsClearByStack, ${__func_return}"
    return 0
  fi
  #APPLICATIONS DIR
  export STACK_APPLICATIONS_DIR=${ROOT_DIR}/applications
  export STACK_APPLICATIONS_DOCKER_DIR=${STACK_APPLICATIONS_DIR}/docker
  export STACK_APPLICATIONS_PROJECT_DIR=${STACK_APPLICATIONS_DIR}/projects
  export STACK_APPLICATIONS_DATA_DIR=${STACK_APPLICATIONS_DIR}/data
  export STACK_APPLICATIONS_DATA_ENV_DIR=${STACK_APPLICATIONS_DATA_DIR}/envs
  export STACK_APPLICATIONS_DATA_ENV_JSON_FILE=${STACK_APPLICATIONS_DATA_ENV_DIR}/env_file_default.json
  export STACK_APPLICATIONS_DATA_CONF_DIR=${STACK_APPLICATIONS_DATA_DIR}/conf
  export STACK_APPLICATIONS_DATA_SRC_DIR=${STACK_APPLICATIONS_DATA_DIR}/source
  export STACK_APPLICATIONS_DATA_DB_DIR=${STACK_APPLICATIONS_DATA_DIR}/db
  export STACK_APPLICATIONS_DATA_SCRIPT_DIR=${STACK_APPLICATIONS_DATA_DIR}/scripts
  export STACK_APPLICATIONS_DATA_VAULT_DIR=${STACK_APPLICATIONS_DATA_DIR}/vault

  if [[ -d ${STACK_APPLICATIONS_DOCKER_DIR} ]]; then
    export STACK_INSTALLER_DOCKER_DIR=${STACK_APPLICATIONS_DOCKER_DIR}
  else
    unset STACK_INSTALLER_DOCKER_DIR
  fi

  #INSTALLER DIR
  if [[ ${STACK_INSTALLER_DOCKER_DIR} == "" ]]; then
    export STACK_INSTALLER_DOCKER_DIR=${INSTALLER_DIR}/docker
  fi

  export STACK_INSTALLER_DOCKER_CONF_DIR=${STACK_INSTALLER_DOCKER_DIR}/conf
  export STACK_INSTALLER_DOCKER_FILE_DIR=${STACK_INSTALLER_DOCKER_DIR}/dockerfiles
  export STACK_INSTALLER_DOCKER_COMPOSE_DIR=${STACK_INSTALLER_DOCKER_DIR}/compose

  export STACK_VAULT_DIR=${STACK_APPLICATIONS_DATA_VAULT_DIR}/${STACK_ENVIRONMENT}
  
  return 1
}

function utilPrepareInit()
{
  local __utilPrepareInit_stack_environment=${1}
  local __utilPrepareInit_stack_target=${2}
  
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

  __privateEnvsDNSList
  if ! [ "$?" -eq 1 ]; then
    echR "  fail on calling __privateEnvsDNSList"
    return 0
  fi

  return 1
}

function prepareStackForDeploy()
{
  local __prepareStackForDeploy_project_dir=${1}
  local __prepareStackForDeploy_project=${2}

  stackEnvsClearByStack
  
  local __prepareStackForDeploy_project_env_file=${__prepareStackForDeploy_project_dir}/${__prepareStackForDeploy_project}
  if [[ -f ${__prepareStackForDeploy_project_env_file} ]]; then
    source ${__prepareStackForDeploy_project_env_file};
  fi

  stackEnvsLoadByStack "${STACK_ENVIRONMENT}" "${STACK_TARGET}" "${__prepareStackForDeploy_project}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackEnvsLoadByStack, ${__func_return}"
    return 0;
  elif [[ ${STACK_SERVICE_STORAGE_DATA_DIR} == "" ]]; then
    export __func_return="env is empty \${STACK_SERVICE_STORAGE_DATA_DIR}"
    return 0
  elif [[ ${STACK_SERVICE_STORAGE_BACKUP_DIR} == "" ]]; then
    export __func_return="env is empty, \${STACK_SERVICE_STORAGE_BACKUP_DIR}"
    return 0
  fi

  if [[ ${APPLICATION_DEPLOY_MODE} == "global" ]]; then
    export APPLICATION_DEPLOY_REPLICAS=1
  fi

  stackMkDir 755 "${STACK_SERVICE_STORAGE_DATA_DIR} ${STACK_SERVICE_STORAGE_BACKUP_DIR}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling prepareStackForDeploy::stackMkDir: ${__func_return}"
    return 0;
  elif ! [[ -d ${STACK_SERVICE_STORAGE_BACKUP_DIR} ]]; then
    export __func_return="dir no exists \${STACK_SERVICE_STORAGE_BACKUP_DIR}: ${STACK_SERVICE_STORAGE_BACKUP_DIR}"
    return 0
  elif ! [[ -d ${STACK_SERVICE_STORAGE_DATA_DIR} ]]; then
    export __func_return="dir no exists, env \${STACK_SERVICE_STORAGE_DATA_DIR}: ${STACK_SERVICE_STORAGE_DATA_DIR}"
    return 0
  else
    return 1
  fi
}