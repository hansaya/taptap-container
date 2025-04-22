ARG BUILD_FROM=alpine:3.21.3
FROM ${BUILD_FROM}

# Environment variables
ENV \
    CARGO_NET_GIT_FETCH_WITH_CLI=true \
    HOME="/root" \
    LANG="C.UTF-8" \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_EXTRA_INDEX_URL="https://wheels.home-assistant.io/musllinux-index/" \
    PIP_NO_CACHE_DIR=1 \
    PIP_PREFER_BINARY=1 \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    YARN_HTTP_TIMEOUT=1000000 \
    TERM="xterm-256color" 

# Set shell
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Install base system
ARG BUILD_ARCH=amd64
ARG BASHIO_VERSION="v0.16.3"
ARG S6_OVERLAY_VERSION="3.2.0.2"
ARG TEMPIO_VERSION="2024.11.2"
RUN \
    set -o pipefail \
    \
    && apk add --no-cache --virtual .build-dependencies \
        tar=1.35-r2 \
        xz=5.6.3-r1 \
    \
    && apk add --no-cache \
        libcrypto3=3.3.3-r0 \
        libssl3=3.3.3-r0 \
        musl-utils=1.2.5-r9 \
        musl=1.2.5-r9 \
    \
    && apk add --no-cache \
        bash=5.2.37-r0 \
        curl=8.12.1-r1 \
        jq=1.7.1-r0 \
        tzdata=2025b-r0

WORKDIR /tmp

# Install python/pip
RUN apk upgrade --no-cache && apk add --no-cache python3 py3-pip curl tar xz libcrypto3 libssl3 musl-utils musl bash jq tzdata

# Get taptap binary
RUN \
    TAPTAP_ARCH="musl-x86_64" \
    && mkdir /usr/bin/taptap \
    && chmod 755 /usr/bin/taptap \
    && curl -sSLf -o /tmp/taptap.tgz \
    "https://github.com/litinoveweedle/taptap/releases/download/v0.1.1/taptap-Linux-${TAPTAP_ARCH}.tar.gz" \
    && tar -xzvf taptap.tgz \
    && cp taptap /usr/bin/taptap/ \
    && chmod 755 /usr/bin/taptap/taptap \
    && rm -Rf /tmp/*

# Get taptap-mqtt bridge
RUN \
    mkdir /etc/taptap \
    && chmod 755 /etc/taptap \
    && curl -sSLf -o /tmp/taptap-mqtt.tgz \
    "https://github.com/litinoveweedle/taptap-mqtt/archive/refs/tags/v0.0.6.tar.gz" \
    && tar -xzvf taptap-mqtt.tgz \
    && cp taptap-mqtt-*/taptap-mqtt.py /usr/bin/taptap/ \
    && chmod 755 /usr/bin/taptap/taptap-mqtt.py \
    && pip install -r taptap-mqtt-*/requirements.txt \
    && rm -Rf /tmp/*

RUN chmod 775 /etc
RUN addgroup -S taptap && adduser -S taptap -G taptap -h /run/taptap -H

USER taptap:taptap
ENTRYPOINT ["python", "/usr/bin/taptap/taptap-mqtt.py", "/tmp/config.ini"]

# Labels
LABEL \
    maintainer="Hans Perera <admin@hansperera.com>" \
    org.opencontainers.image.title="taptap" \
    org.opencontainers.image.description="Tigo taptap to mqtt" \
    org.opencontainers.image.authors="Hans Perera <admin@hansperera.com>" \
    org.opencontainers.image.licenses="Apache 2.0" \
    org.opencontainers.image.url="https://github.com/hansaya/taptap-container" \
    org.opencontainers.image.source="https://github.com/hansaya/taptap-container" \
    org.opencontainers.image.documentation="https://github.com/hansaya/taptap-container/blob/main/README.md"
