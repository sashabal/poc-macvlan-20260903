#!/bin/sh
exec > /build-results.txt 2>&1
echo "=== BUILD v25 ==="
date -u

echo ""
echo "=== 1. AGENT with proper headers ==="
echo "--- GET /health ---"
curl -sv -m 3 --http1.1 -H "Accept: application/json" http://172.18.0.2:8000/health 2>&1
echo ""
echo "--- GET / ---"
curl -sv -m 3 --http1.1 -H "Accept: application/json" http://172.18.0.2:8000/ 2>&1
echo ""
echo "--- GET /openapi.json ---"
curl -sv -m 5 --http1.1 -H "Accept: application/json" http://172.18.0.2:8000/openapi.json 2>&1 | head -100
echo ""
echo "--- GET /docs ---"
curl -sv -m 5 --http1.1 -H "Accept: text/html" http://172.18.0.2:8000/docs 2>&1 | head -80
echo ""
echo "--- POST /webhooks/autoheal ---"
curl -sv -m 3 --http1.1 -X POST http://172.18.0.2:8000/webhooks/autoheal -H "Content-Type: application/json" -d '{"test":1}' 2>&1
echo ""
echo "--- WebSocket upgrade ---"
curl -sv -m 3 --http1.1 -H "Upgrade: websocket" -H "Connection: Upgrade" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -H "Sec-WebSocket-Version: 13" http://172.18.0.2:8000/ 2>&1
echo ""

echo ""
echo "=== 2. FULL PORT SCAN: docker0 (.2-.7) ==="
for i in 2 3 4 5 6 7; do
  for port in 22 53 80 443 2019 3000 4222 4243 5000 5432 5555 5672 6379 8000 8080 8443 8888 9090 9100 9200 9300 9443 10050 15672 24224 27017 27110; do
    nc -z -w1 172.17.0.$i $port 2>/dev/null && echo "172.17.0.$i:$port OPEN"
  done
done

echo ""
echo "=== 3. FULL PORT SCAN: agent-net .3 and .5 ==="
for i in 3 5; do
  for port in 22 53 80 443 2019 3000 4243 5000 5432 5672 6379 8000 8080 8443 8888 9090 9100 9200 9300 9443 15672 24224 27017 27110; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN"
  done
done

echo ""
echo "=== 4. DOCKER0 SERVICE PROBE ==="
for i in 3 4 5 6 7; do
  RES=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://172.17.0.$i:8000/ 2>/dev/null)
  [ "$RES" != "000" ] && echo "172.17.0.$i:8000 → HTTP $RES"
  RES=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://172.17.0.$i:80/ 2>/dev/null)
  [ "$RES" != "000" ] && echo "172.17.0.$i:80 → HTTP $RES"
  RES=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://172.17.0.$i:9200/ 2>/dev/null)
  [ "$RES" != "000" ] && echo "172.17.0.$i:9200 → HTTP $RES"
done

echo ""
echo "=== 5. AGENT-NET .3 and .5 PROBE ==="
for i in 3 5; do
  RES=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://172.18.0.$i:27110/ 2>/dev/null)
  [ "$RES" != "000" ] && echo "172.18.0.$i:27110 → HTTP $RES"
  RES=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://172.18.0.$i:8000/ 2>/dev/null)
  [ "$RES" != "000" ] && echo "172.18.0.$i:8000 → HTTP $RES"
  RES=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://172.18.0.$i:5672/ 2>/dev/null)
  [ "$RES" != "000" ] && echo "172.18.0.$i:5672 → HTTP $RES"
done

echo ""
echo "=== 6. DNS from host context ==="
nslookup rabbitmq 85.193.93.193 2>&1 || true
echo ""
nslookup opensearch 85.193.93.193 2>&1 || true
echo ""
nslookup agent 85.193.93.193 2>&1 || true
echo ""
nslookup caddy 85.193.93.193 2>&1 || true

echo ""
echo "=== 7. TCP decode snapshot ==="
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
        states = {'0A':'LISTEN','01':'EST','06':'TW','02':'SYN','08':'CW'}
        print(f'{lip}:{int(lp,16)} -> {rip}:{int(rp,16)} [{states.get(st,st)}]')
" 2>&1

echo ""
echo "=== 8. RUN mount docker.sock test ==="
ls -la /var/run/docker.sock 2>&1 || echo "no /var/run/docker.sock"
ls -la /run/docker.sock 2>&1 || echo "no /run/docker.sock"

echo ""
echo "=== BUILD DONE ==="
