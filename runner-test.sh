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
  return 1
}

main
 