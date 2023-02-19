FROM debian:latest
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

RUN apt update;
RUN apt install -y sudo telnet zip tar curl htop mcedit iputils-ping openssh-client postgresql-client tmux;