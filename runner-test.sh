#!/bin/bash

export PATH=${PATH}:${BASH_BIN}
export PATH=${PATH}:${PWD}/lib

. ${BASH_BIN}/lib-strings.sh

function main()
{
  envsSetIfIsEmpty XXXXXXH 1234
  return 1
}

main
 