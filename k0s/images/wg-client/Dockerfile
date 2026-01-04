FROM alpine:3.19

RUN apk add --no-cache \
    wireguard-tools \
    iproute2 \
    iptables \
    && mkdir -p /config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
