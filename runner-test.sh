#!/bin/bash

export PATH=${PATH}:${BASH_BIN}
export PATH=${PATH}:${BASH_BIN}
export PATH=${PATH}:${PWD}/lib

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-bash.sh
. ${BASH_BIN}/lib-docker.sh
. ${BASH_BIN}/lib-selector.sh
. ${BASH_BIN}/lib-database.sh
#. ${BASH_BIN}/lib-actions.sh


# . ${INSTALLER_DIR}/lib/util-prepare.sh
# . ${INSTALLER_DIR}/lib/util-selectors.sh
. ${INSTALLER_DIR}/lib/util-runner.sh


function main()
{
  export STACK_DOMAIN="teste.local"
  export STACK_ENVIRONMENT=development
  export STACK_TARGET=company
  export STACK_PREFIX="${STACK_ENVIRONMENT}-${STACK_TARGET}"

  # strArg 0 "teste.1" '.'
  # exit 0
  # jsonGet "/mnt/storage/home/person-job/transul/transul-erp-docker-build/applications/data/envs/env_file_default.json" "env.default"
  # exit 0
  mkdir -p /tmp/srv-agt-wrapper
  __prepare_container_src_dir=/mnt/storage/home/person-job/transul/transul-erp-docker-build/applications/data/envs/env_file_default.json
  __prepare_container_name=srv-agt-wrapper
  __prepare_container_tags="env.default env.erp docker_env.default docker_env.srv_agt_wrapper"  
  __prepare_container_destine_dir=/home/debian/build/development-transul-srv-agt-wrapper
  __private_prepareContainerEnvs "${__prepare_container_src_dir}" "${__prepare_container_name}" "${__prepare_container_tags}" "${__prepare_container_destine_dir}"

  exit 0
  # strSplit "flavio portela"
  # strExtractFilePath "/teste/file.txt"
  # strExtractFileName "/teste/file.txt"
  # strExtractFileExtension "/teste/file.txt"
}

main
 