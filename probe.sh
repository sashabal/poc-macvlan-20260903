#!/bin/sh
echo "=== macvlan network probe ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "--- interfaces ---" >> /app/index.html
ip addr 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- routes ---" >> /app/index.html
ip route 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- arp ---" >> /app/index.html
ip neigh 2>&1 >> /app/index.html
echo "" >> /app/index.html

echo "--- /etc/resolv.conf ---" >> /app/index.html
cat /etc/resolv.conf >> /app/index.html
echo "" >> /app/index.html

echo "--- scan local subnet ---" >> /app/index.html
for i in 1 2 3 4 5 10 20 50 100 200 254; do
  RESULT=$(curl -s -m 1 -o /dev/null -w "%{http_code}" "http://172.18.0.${i}:8080/" 2>/dev/null)
  if [ "$RESULT" != "000" ]; then
    echo "172.18.0.${i}:8080 → HTTP $RESULT" >> /app/index.html
  fi
done
echo "" >> /app/index.html

echo "--- agent access ---" >> /app/index.html
curl -sv -m 3 "http://agent:8000/health" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== done ===" >> /app/index.html
cd /app && python3 -m http.server 8080
