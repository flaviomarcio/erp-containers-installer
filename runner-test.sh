#!/bin/bash

export PATH=${PATH}:${BASH_BIN}
export PATH=${PATH}:${PWD}/lib

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-scripts.sh

function main()
{
  #scriptsPrepare production "/mnt/storage/home/person-job/transul/erp-docker-build/applications/data/scripts"
  #scriptsExecute
  return 1
}

main
 