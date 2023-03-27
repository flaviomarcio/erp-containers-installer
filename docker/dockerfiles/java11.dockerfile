FROM openjdk:11
LABEL maintainer flavio.portela

ENV TZ=America/Sao_Paulo

RUN apt update;
RUN apt install -y tzdata;


COPY ${BUILD_TEMP_APP_DATA_DIR} /

ENV HOME /app
ENV WORK /app

ENTRYPOINT ["java","-jar","/app/app.jar"]
#ENTRYPOINT ["ls","-l","/app"]