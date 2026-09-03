#!/bin/sh
echo "=== v17: dns + dns_search + logging test ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html

echo "" >> /app/index.html
echo "=== 1. DNS CONFIG (resolv.conf) ===" >> /app/index.html
cat /etc/resolv.conf >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 2. DNS RESOLUTION TESTS ===" >> /app/index.html
echo "--- google.com ---" >> /app/index.html
nslookup google.com >> /app/index.html 2>&1
echo "--- evil.example.com (dns_search suffix) ---" >> /app/index.html
nslookup test >> /app/index.html 2>&1
echo "--- agent hostname ---" >> /app/index.html
nslookup agent >> /app/index.html 2>&1
echo "--- rabbitmq ---" >> /app/index.html
nslookup rabbitmq >> /app/index.html 2>&1
echo "--- opensearch ---" >> /app/index.html
nslookup opensearch >> /app/index.html 2>&1
echo "--- elasticsearch ---" >> /app/index.html
nslookup elasticsearch >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 3. INTERFACES ===" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 4. ROUTES ===" >> /app/index.html
ip route show >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 5. ARP TABLE ===" >> /app/index.html
ip neigh show >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 6. DOCKER BRIDGE GATEWAY (172.18.0.1) ===" >> /app/index.html
curl -sv -m 3 http://172.18.0.1:8000/health >> /app/index.html 2>&1
echo "" >> /app/index.html
curl -sv -m 3 http://172.18.0.1:80/ >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 7. HOST SSH BANNER ===" >> /app/index.html
echo "" | nc -w2 $(ip route | grep default | awk '{print $3}') 22 >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== 8. LOGGING DRIVER TEST ===" >> /app/index.html
echo "If syslog driver accepted, this line goes to syslog too" >> /app/index.html
echo "Logging driver info:" >> /app/index.html
# Check if stdout/stderr go to syslog
ls -la /dev/stdout /dev/stderr >> /app/index.html 2>&1

echo "" >> /app/index.html
echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html

cd /app && python3 -m http.server 8080
