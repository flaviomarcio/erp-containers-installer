FROM debian:bullseye
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ENV TZ=America/Sao_Paulo

RUN apt update && apt-get upgrade -y 
#basic setup
RUN apt-get install -y \
    libglib2.0-0 libdw1 openssh-client postgresql-client libjemalloc2 libmemcached11 libnss3
#Qt GUI
RUN apt-get install -y \
    xvfb libxcb-util1 libxkbcommon-tools libegl1 poppler-utils \
    libxcb-cursor0 libxcb-icccm4 libxcb-keysyms1 libxcb-shape0 libdbus-1-3

RUN mkdir -p /home/debian/app

ENV XDG_RUNTIME_DIR /home/debian/app
#0: disable message, 1: export messages 
ENV QT_DEBUG_PLUGINS=0
ENV QT_LIBRARY_PATH /home/debian/qt
ENV QT_PLUGIN_PATH /home/debian/qt/plugins
ENV QT_QPA_PLATFORM_PLUGIN_PATH /home/debian/qt/plugins/platforms
ENV LD_LIBRARY_PATH /home/debian/qt/lib:/home/debian/qt/plugins
ENV PATH $PATH:/home/debian/qt/lib:/home/debian/qt/plugins
ENV HOME /home/debian

ADD ./app /home/debian/app/app
ADD ./startRun /home/debian/app/startRun

VOLUME /home/debian/qt
WORKDIR /home/debian/app
ENTRYPOINT ["sh", "./startRun"]