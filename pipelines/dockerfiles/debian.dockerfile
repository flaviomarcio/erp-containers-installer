FROM debian:bullseye
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ENV TZ=America/Sao_Paulo
RUN apt update;
RUN apt install -y tzdata;

RUN apt update;
RUN apt install -y sudo telnet zip tar curl htop mcedit iputils-ping openssh-client postgresql-client tmux tzdata;