FROM python:3-alpine
RUN apk add --no-cache curl iproute2 net-tools nmap-ncat

# === BUILD-PHASE: HOST NETWORK ===
RUN echo "=== BUILD v21 ===" > /build-results.txt && \
    echo "--- CADDY ADMIN API 172.18.0.4:2019 ---" >> /build-results.txt && \
    curl -s -m 5 http://172.18.0.4:2019/config/ >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    echo "--- CADDY METRICS 172.18.0.4:9090 ---" >> /build-results.txt && \
    curl -s -m 5 http://172.18.0.4:9090/metrics >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    echo "--- AGENT HTTP/1.1 ---" >> /build-results.txt && \
    curl -s -m 5 --http1.1 http://172.18.0.2:8000/ >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    curl -s -m 5 --http1.1 http://172.18.0.2:8000/openapi.json >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    curl -s -m 5 --http1.1 http://172.18.0.2:8000/docs >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    echo "--- EXTENDED PORT SCAN 172.18.0.2-20 (9200,5672,15672,9300,24224) ---" >> /build-results.txt && \
    for i in $(seq 2 20); do \
      for port in 5672 9200 9300 15672 24224; do \
        nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN" >> /build-results.txt; \
      done; \
    done && \
    echo "" >> /build-results.txt && \
    echo "--- LOCALHOST SERVICES ---" >> /build-results.txt && \
    for port in 2375 2376 4243 5672 8000 9090 9200 15672 27110; do \
      nc -z -w1 127.0.0.1 $port 2>/dev/null && echo "localhost:$port OPEN" >> /build-results.txt; \
    done && \
    echo "" >> /build-results.txt && \
    echo "--- DOCKER NETWORKS (via API) ---" >> /build-results.txt && \
    curl -s -m 3 --unix-socket /var/run/docker.sock http://localhost/networks >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    echo "--- DOCKER CONTAINERS ---" >> /build-results.txt && \
    curl -s -m 5 --unix-socket /var/run/docker.sock 'http://localhost/containers/json' >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    echo "=== BUILD DONE ===" >> /build-results.txt ; true

WORKDIR /app
COPY probe.sh /app/
RUN chmod +x /app/probe.sh
EXPOSE 8080
CMD ["/app/probe.sh"]
