FROM debian:bullseye
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

RUN useradd -m debian -s /bin/bash
RUN usermod -aG root debian
RUN usermod -aG sudo debian
RUN mkdir -p /home/debian

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
    sudo tar curl \
    libglib2.0-0 libdw1 openssh-client postgresql-client libjemalloc2 \
    unixodbc freetds-bin tdsodbc htop mcedit iputils-ping libnss3 libmemcached11 \
    libegl1 libxcb-xinerama0 libgl1-mesa-glx libxkbcommon-tools libxcb-util1 xvfb \
    imagemagick exiftool poppler-utils


ENV XDG_RUNTIME_DIR /run/user/debian
ENV PUBLIC_LIB_DIR /home/debian/lib 

ENV HOME /home/debian
ENV LIB_PATH ${PUBLIC_LIB_DIR}
ENV INSTALER_PATH ${HOME}/installer
ENV WORK_PATH ${HOME}/app
ENV BASHRC_FILE ${WORK_PATH}/bashrc.sh

RUN echo "#load application envs" >> ${HOME}/.bashrc
RUN echo "if [[ -f ${BASHRC_FILE} ]]; then" >> ${HOME}/.bashrc
RUN echo "  source ${BASHRC_FILE}" >> ${HOME}/.bashrc
RUN echo "fi" >> ${HOME}/.bashrc

#ADD ${STACK_INSTALLER_DOCKER_SSH_KEYS_DIR} /home/ssh
ADD ${STACK_INSTALLER_DIR} ${HOME}
ADD ${APPLICATION_DEPLOY_APP_DIR} ${HOME}

# COPY ${APPLICATION_DEPLOY_APP_DIR} ${WORK}

WORKDIR ${WORK_PATH}
#CMD ["./startRun"]
CMD ["sleep","infinity"]