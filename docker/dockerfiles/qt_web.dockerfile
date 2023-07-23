FROM nginx
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ENV TZ=America/Sao_Paulo
RUN apt update;
RUN apt install -y tzdata;

#COPY ${BUILD_APP_DIR} /
ADD ${APPLICATION_DEPLOY_APP_DIR} /
ADD ${APPLICATION_DEPLOY_APP_DIR}/nginx.conf /etc/nginx/

WORKDIR /app