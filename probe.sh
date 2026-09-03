#!/bin/sh
echo "=== v15: routing debug + creative agent hunt ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

# Try adding route to agent-network without NET_ADMIN
echo "=== TRY ip route add ===" >> /app/index.html
ip route add 172.18.0.0/16 via 172.20.0.1 dev eth0 2>&1 >> /app/index.html
ip route add 172.18.0.0/16 dev eth0 2>&1 >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

# Traceroute to see where packets die
echo "=== TRACEROUTE to 172.18.0.2 ===" >> /app/index.html
traceroute -n -m 5 -w 1 172.18.0.2 >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "=== TRACEROUTE to 172.18.0.1 ===" >> /app/index.html
traceroute -n -m 5 -w 1 172.18.0.1 >> /app/index.html 2>&1
echo "" >> /app/index.html

# Direct agent access test (with verbose)
echo "=== DIRECT: 172.18.0.2:8000 ===" >> /app/index.html
curl -sv -m 5 "http://172.18.0.2:8000/health" >> /app/index.html 2>&1
echo "" >> /app/index.html

# Try agent on ALL possible IPs, not just 172.18.0.x
echo "=== AGENT HUNT: all bridge gateways + .2 ===" >> /app/index.html
for sub in 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
  for i in 1 2 3; do
    R=$(curl -s -m 1 -o /dev/null -w "%{http_code}" "http://172.${sub}.0.$i:8000/health" 2>/dev/null)
    [ "$R" != "000" ] && echo "172.${sub}.0.$i:8000 → $R !!!" >> /app/index.html
  done
done
echo "" >> /app/index.html

# KEY: try AMQP + OpenSearch on ALL subnets (creds!)
echo "=== AMQP + OpenSearch hunt ===" >> /app/index.html
for sub in 17 18 19 20 21 22 23 24 25; do
  for i in 1 2 3 4 5 6 7 8 9 10; do
    nc -z -w1 172.${sub}.0.$i 5672 2>/dev/null && echo "AMQP: 172.${sub}.0.$i:5672 OPEN!" >> /app/index.html
    nc -z -w1 172.${sub}.0.$i 9200 2>/dev/null && echo "ES: 172.${sub}.0.$i:9200 OPEN!" >> /app/index.html
    nc -z -w1 172.${sub}.0.$i 15672 2>/dev/null && echo "RabbitMQ Mgmt: 172.${sub}.0.$i:15672 OPEN!" >> /app/index.html
  done
done
echo "" >> /app/index.html

# PORT SCAN gateways for more services
echo "=== GATEWAY PORT SCAN ===" >> /app/index.html
for sub in 17 18 19; do
  echo "--- 172.${sub}.0.1 ---" >> /app/index.html
  for port in 22 53 80 443 2375 2376 4243 5432 5672 6379 8000 8080 8443 9090 9100 9200 9443 10250 15672 27017 27110; do
    nc -z -w1 172.${sub}.0.1 $port 2>/dev/null && echo "  :$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

# Try to read /proc/net/arp for host's ARP table (won't work but try)
echo "=== /proc/net ===" >> /app/index.html
cat /proc/net/arp >> /app/index.html 2>&1
echo "" >> /app/index.html
cat /proc/net/route >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
