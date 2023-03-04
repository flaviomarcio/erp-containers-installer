#!/bin/bash

function main()
{
  if [[ ${PUBLIC_LIB_DIR} == "" ]] ; then
    echo "invalid env: PUBLIC_LIB_DIR"
    return 0;
  fi

  if [[ ${QT_VERSION} == "" ]] ; then
    echo "invalid env: QT_VERSION"
    return 0;
  fi

  if [[ ${STACK_INSTALLER_DIR} != "" ]]; then
    export PATH=${PATH}:${STACK_INSTALLER_DIR}
  fi

  export QT_QPA_PLATFORM=offscreen
  export QT_ACCESSIBILITY=1
  export QT_AUTO_SCREEN_SCALE_FACTOR=0
  export QT_REFORCE_LOG=true

  export QT_DIR=${PUBLIC_LIB_DIR}/qt
  export QT_LIBRARY_PATH=${QT_DIR}/${QT_VERSION}
  export LD_LIBRARY_PATH=${QT_LIBRARY_PATH}/lib
  export QT_PLUGIN_PATH=${QT_LIBRARY_PATH}/plugins
  export QT_QPA_PLATFORM_PLUGIN_PATH=${LD_LIBRARY_PATH}:${QT_PLUGIN_PATH}
}

main "$@"