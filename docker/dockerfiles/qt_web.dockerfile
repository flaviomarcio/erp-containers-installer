FROM nginx
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ENV TZ=America/Sao_Paulo
RUN apt update;
RUN apt install -y tzdata;

ADD ./ /var/www

ADD ./nginx.conf /etc/nginx/nginx.conf