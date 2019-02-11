FROM alpine:3.7
LABEL maintainer "Jérémie COLOMBO <jeremie.colombo@gmail.com>"

RUN set -ex \
    && apk add --no-cache \
    bash mysql-client gzip openssl ncftp openssh-client sshpass \
    py-pip python-dev gcc linux-headers libc-dev \
    && pip install python-swiftclient python-keystoneclient \
    && apk del --no-cache python-dev gcc linux-headers libc-dev

COPY start.sh dobackup.sh docompress.sh dosend.sh dodump.sh /

RUN set -x \
    && chmod +x /*.sh \
    && mkdir /backups

CMD ["/start.sh"]