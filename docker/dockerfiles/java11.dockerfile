FROM openjdk:11
LABEL maintainer flavio.portela

COPY ${BUILD_APP_DIR} /

ENV HOME /app
ENV WORK /app

ENTRYPOINT ["java","-jar","/app/app.jar"]
#ENTRYPOINT ["ls","-l","/app"]