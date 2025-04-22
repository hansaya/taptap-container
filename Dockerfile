ARG BUILD_FROM
FROM amd64/alpine:3.21.3

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

USER nonroot:nonroot
ENTRYPOINT ["/usr/bin/taptap/taptap-mqtt.py /data/config.ini"]

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
