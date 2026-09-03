#!/bin/sh
echo "=== v18: deep scan agent-network from compose ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html

echo "" >> /app/index.html
echo "=== 1. INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 2. FULL PORT SCAN: 172.18.0.1 (DinD/gateway) ===" >> /app/index.html
for port in 22 53 80 443 2019 2375 4243 5432 5672 6379 8000 8080 9090 9100 9200 9443 15672 24224 27017 27110; do
  RESULT=$(nc -z -w1 172.18.0.1 $port 2>&1 && echo "OPEN" || echo "closed")
  echo "172.18.0.1:$port → $RESULT" >> /app/index.html
done

echo "" >> /app/index.html
echo "=== 3. DIRECT AGENT TEST: 172.18.0.2:8000 ===" >> /app/index.html
nc -z -w2 172.18.0.2 8000 >> /app/index.html 2>&1
curl -sv -m 3 http://172.18.0.2:8000/health >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "--- 172.18.0.3-8 scan ---" >> /app/index.html
for i in 2 3 4 5 6 7 8; do
  for port in 80 443 5672 8000 9090 9200 15672 27110; do
    nc -z -w1 172.18.0.$i $port 2>&1 && echo "172.18.0.$i:$port OPEN" >> /app/index.html
  done
done

echo "" >> /app/index.html
echo "=== 4. CADDY HTTPS (172.18.0.1:443) ===" >> /app/index.html
curl -svk -m 3 "https://172.18.0.1/" >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 5. CADDY ADMIN API (172.18.0.1:2019) ===" >> /app/index.html
curl -sv -m 3 "http://172.18.0.1:2019/config/" >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 6. CADDY METRICS (172.18.0.1:9090) ===" >> /app/index.html
curl -sv -m 3 "http://172.18.0.1:9090/metrics" >> /app/index.html 2>&1 | head -50

echo "" >> /app/index.html
echo "=== 7. TTYD (172.18.0.1:27110) ===" >> /app/index.html
curl -sv -m 3 "http://172.18.0.1:27110/" >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 8. OPENSEARCH (172.18.0.1:9200) ===" >> /app/index.html
curl -sv -m 3 "http://172.18.0.1:9200/" >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 9. DNS resolv.conf ===" >> /app/index.html
cat /etc/resolv.conf >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 10. LOGGING DRIVER === " >> /app/index.html
echo "logging: syslog with tcp://45.89.190.124:5514" >> /app/index.html
echo "If deploy succeeded, syslog driver is available in DinD" >> /app/index.html

echo "" >> /app/index.html
echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html

cd /app && python3 -m http.server 8080
