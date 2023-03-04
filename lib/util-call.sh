#!/bin/bash

. ${BASH_BIN}/bash-util.sh
. ${STACK_INSTALLER_DIR}/lib/util-prepare.sh

function __privateCallWithDisplay()
{
  SCRIPTPATH="$( cd "`dirname "$1"`" ; pwd -P )"
  export BINARY=$1

  export XDG_RUNTIME_DIR=/tmp/runtime-invservernode
  export TZ=:/etc/localtime

  mkdir -p ${XDG_RUNTIME_DIR}
  chmod 0700 ${XDG_RUNTIME_DIR}

  function clean_exit() {
      pkill -9 -f "Xvfb.*:$C"
  }

  trap "clean_exit" EXIT KILL TERM

  export DISPLAY=":0"
  Xvfb ${DISPLAY} -nolisten tcp -extension RANDR -screen 0 1280x800x24 &
  sleep 2

  # export LD_LIBRARY_PATH=/opt/Qt5.12.5/5.12.5/gcc_64/lib
  # export QT_PLUGIN_PATH=/opt/Qt5.12.5/5.12.5/gcc_64/plugins

  cd "${SCRIPTPATH}"

  while true
  do
      LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 ${BINARY} 2>&1 | tee -a general.log
      sleep 2
  done
}


function callWithDisplay()
{
  RUN_FILE=${1}
  BASE_DIR=$(dirname ${RUN_FILE})

  if ! [[ -f ${RUN_FILE} ]]; then
    echo "Invalid filename"
    return 0;
  fi

  __privateCallWithDisplay "$@"

  cd ${BASE_DIR}
  if [[ -d ./core ]]; then
    rm -rf ./core
  fi

  return 1;
}