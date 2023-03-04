FROM debian:latest
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

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
RUN mkdir -p /home/debian

USER debian

# RUN apt update;
# RUN apt install -y \
#         sudo tar curl libglib2.0-0 libdw1 openssh-client postgresql-client libjemalloc2;

# RUN apt install -y \
#         unixodbc freetds-bin tdsodbc htop mcedit iputils-ping libnss3 libmemcached11;

# RUN apt install -y \
#         libegl1 libxcb-xinerama0 libgl1-mesa-glx libxkbcommon-tools libxcb-util1 xvfb;

# RUN apt install -y \
#         imagemagick exiftool poppler-utils;


ADD --chown=debian:debian ${STACK_INSTALLER_DIR} /home/debian/installer
ADD --chown=debian:debian ${STACK_INSTALLER_DOCKER_SSH_KEYS_DIR} ./ssh
ADD --chown=debian:debian ${APPLICATION_DEPLOY_DATA_DIR} ${WORK_PATH}

# COPY ${APPLICATION_DEPLOY_DATA_DIR} ${WORK}

WORKDIR ${WORK_PATH}
#CMD ["./startRun"]
CMD ["sleep","infinity"]