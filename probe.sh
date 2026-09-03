#!/bin/sh
echo "=== ipvlan L3 + cap_add probe v3 ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "--- interfaces ---" >> /app/index.html
ip -d addr 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- ip -d link ---" >> /app/index.html
ip -d link 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- routes ---" >> /app/index.html
ip route 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- capabilities ---" >> /app/index.html
cat /proc/self/status 2>&1 | grep -i cap >> /app/index.html
echo "" >> /app/index.html

echo "--- try host eth0 172.18.0.1 various ports ---" >> /app/index.html
for port in 22 80 443 2375 2376 5000 6443 8000 8080 9090 9100; do
  nc -z -w1 172.18.0.1 $port 2>/dev/null && echo "172.18.0.1:$port OPEN" >> /app/index.html
done
echo "" >> /app/index.html

echo "--- host VM public IP scan ---" >> /app/index.html
for port in 22 80 443 2375 5000 8000 8080 9090 9100; do
  nc -z -w1 45.89.190.124 $port 2>/dev/null && echo "45.89.190.124:$port OPEN" >> /app/index.html
done
echo "" >> /app/index.html

echo "--- scan default gw and docker gw ---" >> /app/index.html
for gw in 172.19.0.1 172.18.0.1 172.20.0.1; do
  for port in 22 80 443 2375 2376 5000 8000 8080 9090 9100 9443; do
    nc -z -w1 $gw $port 2>/dev/null && echo "$gw:$port OPEN" >> /app/index.html
  done
done
echo "" >> /app/index.html

echo "--- try docker socket ---" >> /app/index.html
curl -s --unix-socket /var/run/docker.sock http://localhost/info 2>&1 | head -c 200 >> /app/index.html
echo "" >> /app/index.html

echo "--- /proc/net/arp ---" >> /app/index.html
cat /proc/net/arp 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- arp broadcast ---" >> /app/index.html
arping -c 2 -I eth0 172.20.0.1 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "=== done ===" >> /app/index.html
cd /app && python3 -m http.server 8080
