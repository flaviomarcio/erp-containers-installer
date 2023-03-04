FROM nginx
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

#COPY ${BUILD_APP_DIR} /
ADD ${APPLICATION_DEPLOY_APP_DIR} /
ADD ${APPLICATION_DEPLOY_APP_DIR}/nginx.conf /etc/nginx/

ENV WORWORK_PATH /app
WORKDIR ${WORK_PATH}