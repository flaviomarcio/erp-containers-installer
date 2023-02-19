FROM postgres
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ENV POSTGRES_USER ${POSTGRES_USER}
ENV POSTGRES_PASSWORD ${POSTGRES_PASSWORD}

#RUN apt update;
#RUN apt install -y zip tar curl htop atop iotop mcedit iputils-ping;