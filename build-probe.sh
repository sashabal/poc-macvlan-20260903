#!/bin/sh
exec > /build-results.txt 2>&1
echo "=== BUILD v27 — DEFAULT network (no build.network:host!) ==="
date -u

echo ""
echo "=== INTERFACES ==="
ip -4 addr show

echo ""
echo "=== ROUTES ==="
ip route show

echo ""
echo "=== AGENT 172.18.0.2:8000 (agent-network) ==="
curl -sv -m 3 --http1.1 http://172.18.0.2:8000/health 2>&1

echo ""
echo "=== AGENT 172.17.0.2:8000 (docker0) ==="
curl -sv -m 3 --http1.1 http://172.17.0.2:8000/health 2>&1

echo ""
echo "=== CADDY 172.17.0.4:9090 (docker0) ==="
curl -s -m 3 http://172.17.0.4:9090/metrics 2>&1 | head -10

echo ""
echo "=== PORT SCAN docker0 .2-.7 ==="
for i in 2 3 4 5 6 7; do
  for port in 8000 80 443 9090 5672 9200; do
    nc -z -w1 172.17.0.$i $port 2>/dev/null && echo "172.17.0.$i:$port OPEN"
  done
done

echo ""
echo "=== PORT SCAN agent-net .2-.5 ==="
for i in 2 3 4 5; do
  for port in 8000 80 443 9090; do
    nc -z -w1 172.18.0.$i $port 2>/dev/null && echo "172.18.0.$i:$port OPEN"
  done
done

echo ""
echo "=== /proc/net/tcp ==="
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
        states = {'0A':'LISTEN','01':'EST','06':'TW'}
        if st in states: print(f'{lip}:{int(lp,16)} -> {rip}:{int(rp,16)} [{states[st]}]')
" 2>&1

echo ""
echo "=== BUILD DONE ==="
