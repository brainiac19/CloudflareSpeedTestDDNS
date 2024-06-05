FROM alpine:latest

RUN apk add --no-cache \
    bash \
    wget \
    curl \
    jq \
    tar \
    sed \
    gawk \
    coreutils \
    dcron

WORKDIR /app
COPY ./start.sh ./config.conf ./cf_ddns ./
RUN chmod +x ./start.sh ./config.conf ./cf_ddns

COPY ./docker_install.sh /tmp/docker_install.sh
RUN chmod +x /tmp/docker_install.sh && /tmp/docker_install.sh

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
