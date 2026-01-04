FROM alpine:3.19

RUN apk add --no-cache \
    xl2tpd \
    ppp \
    iptables \
    iproute2 \
    && mkdir -p /etc/xl2tpd /etc/ppp /var/run/xl2tpd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
