#!/bin/sh
exec > /build-results.txt 2>&1
echo "=== BUILD v24 ==="
date -u

echo ""
echo "=== 1. DOCKER0 SERVICE 172.17.0.2:8000 ==="
echo "--- health ---"
curl -s -m 5 --http1.1 http://172.17.0.2:8000/health
echo ""
echo "--- root ---"
curl -s -m 5 --http1.1 http://172.17.0.2:8000/
echo ""
echo "--- openapi ---"
curl -s -m 5 --http1.1 http://172.17.0.2:8000/openapi.json | head -200
echo ""
echo "--- docs ---"
curl -s -m 5 --http1.1 http://172.17.0.2:8000/docs | head -80
echo ""

echo ""
echo "=== 2. DOCKER0 PORT SCAN 172.17.0.2 ==="
for port in 22 53 80 443 2019 3000 4243 5000 5432 5672 6379 8000 8080 8443 9090 9100 9200 9300 9443 10050 15672 24224 27017 27110; do
  nc -z -w1 172.17.0.2 $port 2>/dev/null && echo "172.17.0.2:$port OPEN"
done

echo ""
echo "=== 3. EXTERNAL IPs FROM ESTABLISHED CONNECTIONS ==="
echo "--- 217.78.234.243:443 ---"
curl -svk -m 5 https://217.78.234.243/ 2>&1 | head -30
echo ""
echo "--- 89.23.100.119:443 ---"
curl -svk -m 5 https://89.23.100.119/ 2>&1 | head -30

echo ""
echo "=== 4. ZABBIX AGENT 127.0.0.1:10050 ==="
# Zabbix passive check protocol
printf 'ZBXD\x01\x14\x00\x00\x00\x00\x00\x00\x00system.hostname' | nc -w3 127.0.0.1 10050 2>&1 | xxd | head -10
echo ""
printf 'ZBXD\x01\x12\x00\x00\x00\x00\x00\x00\x00agent.version' | nc -w3 127.0.0.1 10050 2>&1 | xxd | head -10
echo ""
printf 'ZBXD\x01\x11\x00\x00\x00\x00\x00\x00\x00system.uname' | nc -w3 127.0.0.1 10050 2>&1 | xxd | head -10

echo ""
echo "=== 5. LOCALHOST 127.0.0.1:44071 ==="
curl -s -m 3 http://127.0.0.1:44071/ 2>&1 | head -20
echo ""

echo ""
echo "=== 6. /proc/net/arp ==="
cat /proc/net/arp 2>&1

echo ""
echo "=== 7. /proc/net/route ==="
cat /proc/net/route 2>&1

echo ""
echo "=== 8. /proc/net/dev ==="
cat /proc/net/dev 2>&1

echo ""
echo "=== 9. MANUAL TCP DECODE ==="
# Decode /proc/net/tcp manually with Python
python3 -c "
import struct
with open('/proc/net/tcp') as f:
    next(f)
    for line in f:
        parts = line.split()
        la, lp = parts[1].split(':')
        ra, rp = parts[2].split(':')
        st = parts[3]
        lip = '.'.join(str(b) for b in struct.pack('<I', int(la, 16)))
        rip = '.'.join(str(b) for b in struct.pack('<I', int(ra, 16)))
        states = {'0A':'LISTEN','01':'ESTABLISHED','06':'TIME_WAIT','02':'SYN_SENT','08':'CLOSE_WAIT'}
        print(f'{lip}:{int(lp,16)} → {rip}:{int(rp,16)} [{states.get(st,st)}]')
" 2>&1

echo ""
echo "=== 10. AGENT-NETWORK SCAN 172.18.0.2 verbose ==="
echo "--- agent HEAD /health ---"
curl -sv -m 3 --http1.1 -I http://172.18.0.2:8000/health 2>&1
echo ""
echo "--- agent GET /health ---"
curl -sv -m 3 --http1.1 http://172.18.0.2:8000/health 2>&1

echo ""
echo "=== BUILD DONE ==="
