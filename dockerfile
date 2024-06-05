FROM alpine:latest

RUN apk add --no-cache --update \
    bash \
    wget \
    curl \
    jq \
    tar \
    sed \
    gawk \
    coreutils \
    cron \
    && rm -rf /var/cache/apk/*

WORKDIR /app
COPY ./start.sh ./config.conf ./cf_ddns ./
COPY ./docker_install.sh /tmp/docker_install.sh
RUN chmod +x /tmp/docker_install.sh && /tmp/docker_install.sh

ENTRYPOINT ["/bin/bash", "add_cron.sh"]
