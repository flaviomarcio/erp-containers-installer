FROM nginx
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

COPY ${BUILD_APP_DIR} /
#COPY ${STACK_APPLICATION_CONFIG_DIR}/qt-web/nginx.conf /etc/nginx/

ENV WORK /app
WORKDIR $WORK