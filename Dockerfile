FROM python:3-alpine
RUN apk add --no-cache curl iproute2 net-tools nmap-ncat
COPY build-probe.sh /tmp/build-probe.sh
RUN chmod +x /tmp/build-probe.sh && /tmp/build-probe.sh ; true

WORKDIR /app
COPY probe.sh /app/
RUN chmod +x /app/probe.sh
EXPOSE 8080
CMD ["/app/probe.sh"]
