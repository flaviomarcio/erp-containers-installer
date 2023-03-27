FROM mysql
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ADD ./config-file.cnf /etc/mysql/conf.d/config-file.cnf


# ENV MYSQL_ALLOW_EMPTY_PASSWORD yes
# ENV MYSQL_ROOT_PASSWORD ${APPLICATION_DB_PASSWORD}
# ENV MYSQL_DATABASE ${APPLICATION_DB_DATABASE}
# ENV MYSQL_USER ${APPLICATION_DB_USER}
# ENV MYSQL_PASSWORD ${APPLICATION_DB_PASSWORD}

#RUN apt update;
#RUN apt install -y zip tar curl htop atop iotop mcedit iputils-ping;