FROM debian:latest
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

RUN apt update;
RUN apt install -y \
        sudo tar curl libglib2.0-0 libdw1 openssh-client postgresql-client libjemalloc2 \
        unixodbc freetds-bin tdsodbc htop mcedit iputils-ping libnss3 libmemcached11 \
        #GUI
        libegl1 libxcb-xinerama0 libgl1-mesa-glx libxkbcommon-tools libxcb-util1 xvfb \ 
        imagemagick exiftool poppler-utils;

        #libgl1-mesa

RUN useradd -G root debian

ENV QT_LIBRARY_PATH /home/debian/qt
ENV QT_DIR /home/debian/qt
ENV QT_ACCESSIBILITY 1
ENV QT_AUTO_SCREEN_SCALE_FACTOR 0
ENV XDG_RUNTIME_DIR /run/user/debian
ENV LD_LIBRARY_PATH ${QT_LIBRARY_PATH}/lib
ENV QT_PLUGIN_PATH ${QT_LIBRARY_PATH}/plugins
ENV QT_QPA_PLATFORM=offscreen
ENV QT_QPA_PLATFORM_PLUGIN_PATH ${LD_LIBRARY_PATH}:${QT_PLUGIN_PATH}

COPY ${BUILD_TEMP_APP_BIN_SRC_DIR} /home/debian
COPY ${STACK_APPLICATION_CONFIG_DIR}/qt-api/startbin.sh /home/debian/startbin.sh

ENV QT_REFORCE_LOG=true
ENV HOME /home/debian
ENV WORK /home/debian/app

WORKDIR ${WORK}
CMD ["./startRun"]
CMD ["sleep","infinity"]