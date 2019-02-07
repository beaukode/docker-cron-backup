FROM alpine:3.7
LABEL maintainer "Jérémie COLOMBO <jeremie.colombo@gmail.com>"

RUN set -ex \
    && apk add --no-cache \
    bash mysql-client gzip openssl ncftp openssh-client sshpass \
    py-pip python-dev gcc linux-headers libc-dev \
    && pip install python-swiftclient python-keystoneclient \
    && apk del --no-cache python-dev gcc linux-headers libc-dev

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

COPY start.sh dobackup.sh docompress.sh dosend.sh /

RUN set -x \
    && chmod +x /*.sh \
    && mkdir /backups

CMD ["/start.sh"]