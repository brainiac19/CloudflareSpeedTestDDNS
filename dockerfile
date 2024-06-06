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
    dcron \
    tzdata

WORKDIR /app
COPY start.sh entrypoint.sh ./
COPY cf_ddns ./cf_ddns
RUN chmod +x start.sh entrypoint.sh && chmod -R +x ./cf_ddns

COPY docker_install.sh /tmp/docker_install.sh
RUN chmod +x /tmp/docker_install.sh
RUN /tmp/docker_install.sh

RUN ls -l /app
STOPSIGNAL SIGKILL

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
CMD ["crond", "-f"]
