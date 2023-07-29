FROM openjdk:11
LABEL maintainer flavio.portela

ENV TZ=America/Sao_Paulo
RUN apt update;
RUN apt install -y tzdata;

COPY . /app

ENV HOME /app
ENV WORK /app

ENTRYPOINT ["java","-jar","/app/app.jar"]