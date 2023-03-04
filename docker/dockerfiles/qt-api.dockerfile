FROM debian:bullseye
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

USER root

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
    sudo tar curl \
    libglib2.0-0 libdw1 openssh-client postgresql-client libjemalloc2 \
    unixodbc freetds-bin tdsodbc htop mcedit iputils-ping libnss3 libmemcached11 \
    libegl1 libxcb-xinerama0 libgl1-mesa-glx libxkbcommon-tools libxcb-util1 xvfb \
    imagemagick exiftool poppler-utils

ENV QT_LIBRARY_PATH /home/debian/qt
ENV QT_DIR /home/debian/qt
ENV QT_ACCESSIBILITY 1
ENV QT_AUTO_SCREEN_SCALE_FACTOR 0
ENV XDG_RUNTIME_DIR /run/user/debian
ENV LD_LIBRARY_PATH ${STACK_INSTALLER_DIR}:${QT_LIBRARY_PATH}/lib
ENV QT_PLUGIN_PATH ${QT_LIBRARY_PATH}/plugins
ENV QT_QPA_PLATFORM=offscreen
ENV QT_QPA_PLATFORM_PLUGIN_PATH ${LD_LIBRARY_PATH}:${QT_PLUGIN_PATH}

ENV HOME /home/debian
ENV WORK_PATH ${HOME}/app
ENV QT_REFORCE_LOG=true

RUN useradd -m debian -s /bin/bash
RUN usermod -aG root debian
RUN usermod -aG sudo debian
RUN mkdir -p /home/debian

#ADD ${STACK_INSTALLER_DOCKER_SSH_KEYS_DIR} /home/ssh
ADD ${STACK_INSTALLER_DIR} /home/debian/installer
ADD ${APPLICATION_DEPLOY_APP_DIR} ${WORK_PATH}

# COPY ${APPLICATION_DEPLOY_APP_DIR} ${WORK}

WORKDIR ${WORK_PATH}
#CMD ["./startRun"]
CMD ["sleep","infinity"]