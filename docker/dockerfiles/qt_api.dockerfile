FROM debian:bullseye
LABEL maintainer "FlavioPortela <fmspx@hotmail.com>"

ENV TZ=America/Sao_Paulo

RUN apt update && apt-get upgrade -y
RUN apt install -y tzdata libglib2.0-0 libdw1 openssh-client postgresql-client libjemalloc2 libnss3 libmemcached11

ADD ./app /app/app
ADD ./startRun /app/startRun
ADD ./startBin /app/startBin

ENV XDG_RUNTIME_DIR /app

ENV HOME /app

WORKDIR /app

ENTRYPOINT ["/app/app"]