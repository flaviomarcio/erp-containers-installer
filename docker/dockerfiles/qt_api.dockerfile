FROM debian:bullseye
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ENV TZ=America/Sao_Paulo
RUN apt update;
RUN apt install -y tzdata;

RUN useradd -m debian -s /bin/bash
RUN usermod -aG root debian
RUN usermod -aG sudo debian
RUN mkdir -p /home/debian

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
    libglib2.0-0 libdw1 openssh-client postgresql-client libjemalloc2 \
    libnss3 libmemcached11 \
    libegl1 libxcb-xinerama0 libgl1-mesa-glx libxkbcommon-tools libxcb-util1 xvfb \
    imagemagick exiftool poppler-utils

ENV XDG_RUNTIME_DIR /run/user/debian

ENV HOME /home/debian

WORKDIR /app
#CMD ["./startRun"]
ENTRYPOINT ["./startRun"]