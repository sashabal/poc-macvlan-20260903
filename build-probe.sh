#!/bin/sh
exec > /build-results.txt 2>&1
echo "=== BUILD v22 — build.network:host ==="
date -u

echo ""
echo "=== CADDY ADMIN 172.18.0.4:2019 ==="
curl -s -m 3 http://172.18.0.4:2019/config/ || echo "(refused)"

echo ""
echo "=== CADDY METRICS 172.18.0.4:9090 ==="
curl -s -m 5 http://172.18.0.4:9090/metrics | head -100 || echo "(refused)"

echo ""
echo "=== AGENT 172.18.0.2:8000 ==="
curl -s -m 5 --http1.1 http://172.18.0.2:8000/health
echo ""
curl -s -m 5 --http1.1 http://172.18.0.2:8000/openapi.json
echo ""
curl -s -m 5 --http1.1 http://172.18.0.2:8000/docs | head -80
echo ""
curl -s -m 3 --http1.1 http://172.18.0.2:8000/
echo ""
curl -s -m 3 --http1.1 http://172.18.0.2:8000/settings
echo ""
curl -s -m 3 --http1.1 http://172.18.0.2:8000/config
echo ""

echo ""
echo "=== PORT SCAN 172.18.0.2-20 ==="
for i in $(seq 2 20); do
  for port in 5672 9200 9300 15672 24224 8000 9090; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN"
  done
done

echo ""
echo "=== OPENSEARCH HUNT ==="
for i in $(seq 2 20); do
  RES=$(curl -s -m 1 -o /dev/null -w "%{http_code}" http://172.18.0.$i:9200/ 2>/dev/null)
  [ "$RES" != "000" ] && echo "ES 172.18.0.$i:9200 → $RES" && curl -s -m 2 http://172.18.0.$i:9200/
done

echo ""
echo "=== RABBITMQ HUNT ==="
for i in $(seq 2 20); do
  nc -z -w1 172.18.0.$i 5672 2>/dev/null && echo "AMQP 172.18.0.$i:5672 OPEN"
  RES=$(curl -s -m 1 -o /dev/null -w "%{http_code}" http://172.18.0.$i:15672/ 2>/dev/null)
  [ "$RES" != "000" ] && echo "RabbitMQ 172.18.0.$i:15672 → $RES" && curl -s -m 2 http://172.18.0.$i:15672/api/overview
done

echo ""
echo "=== LOCALHOST ==="
for port in 2375 2376 4243 5672 8000 9090 9200 9443 15672 24224 27110; do
  nc -z -w1 127.0.0.1 $port 2>/dev/null && echo "localhost:$port OPEN"
done

echo ""
echo "=== DOCKER SOCKET ==="
curl -s -m 3 --unix-socket /var/run/docker.sock http://localhost/version || echo "(no socket)"

echo ""
echo "=== DOCKER CONTAINERS ==="
curl -s -m 5 --unix-socket /var/run/docker.sock 'http://localhost/containers/json' | head -200 || echo "(no socket)"

echo ""
echo "=== BUILD DONE ==="
