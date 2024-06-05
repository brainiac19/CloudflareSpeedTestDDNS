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
COPY . .
RUN ls -l /app

RUN chmod -R +x ./ && ./docker_install.sh

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
