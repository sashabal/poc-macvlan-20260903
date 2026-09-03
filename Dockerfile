FROM python:3-alpine
RUN apk add --no-cache curl iproute2 net-tools traceroute nmap-ncat tcpdump
WORKDIR /app
COPY probe.sh /app/
RUN chmod +x /app/probe.sh
EXPOSE 8080
CMD ["/app/probe.sh"]
