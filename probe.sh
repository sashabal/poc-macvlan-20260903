#!/bin/sh
echo "=== macvlan network probe v2 ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "--- interfaces ---" >> /app/index.html
ip addr 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- routes ---" >> /app/index.html
ip route 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- ip link show ---" >> /app/index.html
ip -d link show 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- scan macvlan subnet 172.20.0.0/24 ---" >> /app/index.html
for i in $(seq 1 254); do
  RESULT=$(curl -s -m 1 -o /dev/null -w "%{http_code}" "http://172.20.0.${i}:80/" 2>/dev/null)
  if [ "$RESULT" != "000" ]; then
    echo "172.20.0.${i}:80 → HTTP $RESULT" >> /app/index.html
  fi
done
echo "macvlan scan done" >> /app/index.html
echo "" >> /app/index.html

echo "--- try host VM IP ---" >> /app/index.html
curl -sv -m 3 "http://45.89.190.124/" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "--- try host docker gateway 172.18.0.1 ---" >> /app/index.html
curl -sv -m 3 "http://172.18.0.1:8000/" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "--- try 172.19.0.1 (default gw) ---" >> /app/index.html
curl -sv -m 3 "http://172.19.0.1:8000/" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "--- agent access via IP ---" >> /app/index.html
for ip in 172.18.0.2 172.19.0.1 172.19.0.3 172.19.0.4 172.19.0.5; do
  RESULT=$(curl -s -m 2 -o /dev/null -w "%{http_code}" "http://${ip}:8000/health" 2>/dev/null)
  if [ "$RESULT" != "000" ]; then
    echo "${ip}:8000/health → HTTP $RESULT" >> /app/index.html
  fi
done
echo "" >> /app/index.html

echo "--- scan macvlan for node_exporter 9100 ---" >> /app/index.html
for i in 1 2 3 4 5 10 100 200 254; do
  RESULT=$(curl -s -m 1 -o /dev/null -w "%{http_code}" "http://172.20.0.${i}:9100/metrics" 2>/dev/null)
  if [ "$RESULT" != "000" ]; then
    echo "172.20.0.${i}:9100 → HTTP $RESULT" >> /app/index.html
  fi
done
echo "" >> /app/index.html

echo "--- scan macvlan for SSH 22 ---" >> /app/index.html
for i in 1 2 3 4 5 10 100 200 254; do
  nc -z -w1 172.20.0.${i} 22 2>/dev/null && echo "172.20.0.${i}:22 OPEN" >> /app/index.html
done
echo "" >> /app/index.html

echo "--- arp table after scan ---" >> /app/index.html
ip neigh 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "=== done ===" >> /app/index.html
cd /app && python3 -m http.server 8080
