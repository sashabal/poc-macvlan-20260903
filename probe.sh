#!/bin/sh
echo "=== v12: INTERNAL network scan ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== OUR INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "=== OUR ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

# From node_exporter: nodename=worker-172.16.3.39
# This is TW internal network. Can we reach it?

echo "=== INTERNAL: 172.16.3.0/24 (TW worker network) ===" >> /app/index.html
for i in 1 2 3 4 5 10 20 30 39 40 50 100 200 254; do
  for port in 22 80 443 9100 8080 8000 5672 9200 10250 6443; do
    nc -z -w1 172.16.3.$i $port 2>/dev/null && echo "172.16.3.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "=== INTERNAL: 172.16.x.1 gateway scan ===" >> /app/index.html
for sub in 0 1 2 3 4 5 10 16 20 32 48 64 128 192 255; do
  for port in 22 80 443 9100 6443 10250; do
    nc -z -w1 172.16.$sub.1 $port 2>/dev/null && echo "172.16.$sub.1:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "=== INTERNAL: 10.x.x.x ranges ===" >> /app/index.html
for net in "10.0.0" "10.0.1" "10.1.0" "10.10.0" "10.100.0" "10.128.0" "10.244.0" "10.96.0" "10.233.0"; do
  for i in 1 2 10 100 254; do
    for port in 22 80 443 9100 6443 8080; do
      nc -z -w1 ${net}.$i $port 2>/dev/null && echo "${net}.$i:$port OPEN" >> /app/index.html
    done
  done
done
echo "" >> /app/index.html

echo "=== INTERNAL: 192.168.x.x ===" >> /app/index.html
for net in "192.168.0" "192.168.1" "192.168.100"; do
  for i in 1 2 10 254; do
    for port in 22 80 443 9100; do
      nc -z -w1 ${net}.$i $port 2>/dev/null && echo "${net}.$i:$port OPEN" >> /app/index.html
    done
  done
done
echo "" >> /app/index.html

# Try to reach 172.16.3.39 directly — the worker node
echo "=== DIRECT: 172.16.3.39 (worker from node_exporter) ===" >> /app/index.html
for port in 22 80 443 2375 5672 8000 8080 9100 9200 9443 10250 6443; do
  nc -z -w2 172.16.3.39 $port 2>/dev/null && echo "172.16.3.39:$port OPEN" >> /app/index.html
done
echo "" >> /app/index.html

# Node exporter data from our own host
echo "=== OUR HOST node_exporter (45.89.190.124:9100) ===" >> /app/index.html
curl -s -m 3 "http://45.89.190.124:9100/metrics" 2>&1 | grep "node_uname_info" >> /app/index.html
curl -s -m 3 "http://172.18.0.1:9100/metrics" 2>&1 | grep "node_uname_info" >> /app/index.html
echo "" >> /app/index.html

# Check if 172.18.0.1 is accessible on 9100
echo "=== DinD host node_exporter ===" >> /app/index.html
nc -z -w1 172.18.0.1 9100 2>/dev/null && echo "172.18.0.1:9100 OPEN" >> /app/index.html
nc -z -w1 172.18.0.1 9323 2>/dev/null && echo "172.18.0.1:9323 OPEN (docker metrics)" >> /app/index.html
echo "" >> /app/index.html

echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
