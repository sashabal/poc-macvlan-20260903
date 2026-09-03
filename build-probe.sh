#!/bin/sh
exec > /build-results.txt 2>&1
echo "=== BUILD v28 — docker0 deep probe ==="
date -u

echo ""
echo "=== AGENT 172.17.0.2:8000 ==="
echo "--- POST /webhooks/autoheal ---"
curl -sv -m 3 --http1.1 -X POST http://172.17.0.2:8000/webhooks/autoheal \
  -H "Content-Type: application/json" \
  -d '{"content":"Container test_00000000-0000 (unhealthy) found dead"}' 2>&1
echo ""
echo "--- GET /health ---"
curl -s -m 3 --http1.1 http://172.17.0.2:8000/health
echo ""

echo ""
echo "=== CADDY 172.17.0.4 ==="
echo "--- admin API 2019 ---"
curl -s -m 3 http://172.17.0.4:2019/config/ 2>&1
echo ""
echo "--- metrics (first 30 lines) ---"
curl -s -m 5 http://172.17.0.4:9090/metrics 2>&1 | head -30
echo ""
echo "--- HTTPS with FQDN ---"
curl -svk -m 5 --resolve "sashabal-poc-macvlan-20260903-44f0.twc1.net:443:172.17.0.4" \
  https://sashabal-poc-macvlan-20260903-44f0.twc1.net/ 2>&1 | head -30

echo ""
echo "=== DOCKER SOCKET ==="
ls -la /var/run/docker.sock 2>&1
curl -s -m 3 --unix-socket /var/run/docker.sock http://localhost/version 2>&1

echo ""
echo "=== FULL PORT SCAN docker0 172.17.0.2 ==="
for port in 22 53 80 443 2019 3000 4243 5000 5432 5555 5672 6379 8000 8080 8443 9090 9100 9200 9300 10050 15672 24224 27017 27110; do
  nc -z -w1 172.17.0.2 $port 2>/dev/null && echo "172.17.0.2:$port OPEN"
done

echo ""
echo "=== FULL PORT SCAN docker0 172.17.0.3-6 ==="
for i in 3 4 5 6; do
  for port in 22 80 443 2019 5672 8000 9090 9100 9200 15672 24224 27110; do
    nc -z -w1 172.17.0.$i $port 2>/dev/null && echo "172.17.0.$i:$port OPEN"
  done
done

echo ""
echo "=== DNS ==="
cat /etc/resolv.conf

echo ""
echo "=== DNS resolve container names ==="
nslookup agent 127.0.0.11 2>&1 || true
echo ""
nslookup caddy 127.0.0.11 2>&1 || true

echo ""
echo "=== BUILD DONE ==="
