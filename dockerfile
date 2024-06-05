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
COPY start.sh entrypoint.sh config.conf ./
COPY cf_ddns ./cf_ddns
RUN chmod +x start.sh entrypoint.sh config.conf && chmox -R +x ./cf_ddns

COPY docker_install.sh /tmp/docker_install.sh
RUN chmod +x /tmp/docker_install.sh
RUN /tmp/docker_install.sh

RUN ls -l /app

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
