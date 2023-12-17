#FROM openjdk:17
FROM openjdk:21-ea-17-bullseye
LABEL maintainer flavio.portela

ENV TZ=America/Sao_Paulo
RUN apt update;
RUN apt install -y curl tzdata;

ADD ./app.jar /app/app.jar

ENV HOME /app
ENV WORK /app

ENTRYPOINT ["java","-jar","/app/app.jar"]