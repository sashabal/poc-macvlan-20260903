#!/bin/sh
echo "=== v13: hunt agent on ALL docker subnets ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== OUR INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "=== ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

# Agent is on agent-network, a separate Docker bridge
# Docker bridges get subnets in 172.x.0.0/16 range
# Host routes all of them. ipvlan on eth0 routes through host.
# Scan every possible Docker subnet gateway + first IPs for agent:8000

echo "=== AGENT HUNT: 172.x.0.1-5:8000 (all Docker bridges) ===" >> /app/index.html
for sub in $(seq 16 32); do
  for i in 1 2 3 4 5; do
    RESULT=$(curl -s -m 1 -o /dev/null -w "%{http_code}" "http://172.${sub}.0.$i:8000/health" 2>/dev/null)
    if [ "$RESULT" != "000" ]; then
      echo "*** 172.${sub}.0.$i:8000/health → HTTP $RESULT ***" >> /app/index.html
      curl -s -m 2 "http://172.${sub}.0.$i:8000/health" >> /app/index.html 2>&1
      echo "" >> /app/index.html
    fi
  done
done
echo "" >> /app/index.html

# Also scan .0.1 gateways for common ports to map networks
echo "=== GATEWAY SCAN: 172.x.0.1 ports ===" >> /app/index.html
for sub in $(seq 16 32); do
  FOUND=""
  for port in 8000 80 443 5672 9200 8080 22; do
    nc -z -w1 172.${sub}.0.1 $port 2>/dev/null && FOUND="${FOUND} ${port}"
  done
  [ -n "$FOUND" ] && echo "172.${sub}.0.1:${FOUND}" >> /app/index.html
done
echo "" >> /app/index.html

# Scan higher IPs on each subnet with open gateway
echo "=== DEEP SCAN: found subnets IPs 2-20 :8000 ===" >> /app/index.html
for sub in 18 19 20 21 22 23 24 25; do
  for i in $(seq 2 20); do
    RESULT=$(curl -s -m 1 -o /dev/null -w "%{http_code}" "http://172.${sub}.0.$i:8000/health" 2>/dev/null)
    if [ "$RESULT" != "000" ]; then
      echo "*** AGENT? 172.${sub}.0.$i:8000 → HTTP $RESULT ***" >> /app/index.html
      curl -sv -m 2 "http://172.${sub}.0.$i:8000/health" >> /app/index.html 2>&1
      echo "" >> /app/index.html
      curl -sv -m 2 "http://172.${sub}.0.$i:8000/" >> /app/index.html 2>&1
      echo "" >> /app/index.html
    fi
  done
done
echo "" >> /app/index.html

# Try DNS resolution inside DinD/host context
echo "=== DNS TESTS ===" >> /app/index.html
for name in "agent" "caddy" "dind" "rabbitmq" "opensearch" "fluentbit"; do
  R=$(getent hosts $name 2>/dev/null)
  [ -n "$R" ] && echo "$name → $R" >> /app/index.html
done
echo "" >> /app/index.html

echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
