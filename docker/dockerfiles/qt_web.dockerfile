FROM nginx
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ENV TZ=America/Sao_Paulo
RUN apt update;
RUN apt install -y tzdata;
RUN apt upgrade -y;

ADD ./ /var/www

ADD ./nginx.conf /etc/nginx/nginx.conf