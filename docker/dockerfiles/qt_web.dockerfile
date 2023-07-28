FROM nginx
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ENV TZ=America/Sao_Paulo
RUN apt update;
RUN apt install -y tzdata;

ADD . /
ADD ./nginx.conf /etc/nginx/

WORKDIR /app