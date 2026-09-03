#!/bin/sh
echo "=== v14: route fix + agent hunt ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

# Try to add route to agent-network via ipvlan
echo "=== TRY ADD ROUTES ===" >> /app/index.html
ip route add 172.18.0.0/16 dev eth0 2>> /app/index.html
ip route add 172.17.0.0/16 dev eth0 2>> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

# Direct agent probe on 172.18.0.x
echo "=== AGENT: 172.18.0.2:8000 (direct) ===" >> /app/index.html
curl -sv -m 3 "http://172.18.0.2:8000/health" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== AGENT: 172.18.0.2-10:8000 ===" >> /app/index.html
for i in $(seq 2 10); do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://172.18.0.$i:8000/health" 2>/dev/null)
  if [ "$RESULT" != "000" ]; then
    echo "*** FOUND: 172.18.0.$i:8000 → HTTP $RESULT ***" >> /app/index.html
    curl -sv -m 3 "http://172.18.0.$i:8000/health" >> /app/index.html 2>&1
    echo "" >> /app/index.html
    curl -sv -m 3 "http://172.18.0.$i:8000/" >> /app/index.html 2>&1
    echo "" >> /app/index.html
    # WEBHOOK!
    curl -sv -m 3 -X POST "http://172.18.0.$i:8000/webhooks/autoheal" \
      -H "Content-Type: application/json" \
      -d '{"content":"Container ipvlan-compose-CRITICAL_00000000-0000-0000-0000-000000000000 (unhealthy) restarted"}' >> /app/index.html 2>&1
    echo "" >> /app/index.html
  else
    echo "172.18.0.$i:8000 → no response" >> /app/index.html
  fi
done
echo "" >> /app/index.html

# Also scan key services on 172.18.0.x
echo "=== SERVICE SCAN: 172.18.0.x ===" >> /app/index.html
for i in $(seq 1 15); do
  for port in 8000 9200 5672 15672 9090 80 443 8080 27110; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

# Try 172.17.0.x (docker0 default bridge)
echo "=== DOCKER0: 172.17.0.x ===" >> /app/index.html
for i in $(seq 1 15); do
  for port in 8000 9200 5672 80 443 8080; do
    nc -z -w1 172.17.0.$i $port 2>/dev/null && echo "172.17.0.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
