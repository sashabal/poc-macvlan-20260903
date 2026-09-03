#!/bin/sh
# Append to existing results if mount tests already wrote something
echo "" >> /build-results.txt
echo "=== FALLBACK BUILD PROBE ===" >> /build-results.txt
date -u >> /build-results.txt

echo "" >> /build-results.txt
echo "--- agent /health ---" >> /build-results.txt
curl -s -m 3 --http1.1 http://172.18.0.2:8000/health >> /build-results.txt 2>&1

echo "" >> /build-results.txt
echo "--- TCP ESTABLISHED ---" >> /build-results.txt
python3 -c "
import struct
with open('/proc/net/tcp') as f:
    next(f)
    for line in f:
        parts = line.split()
        la, lp = parts[1].split(':')
        ra, rp = parts[2].split(':')
        st = parts[3]
        if st in ('01', '0A'):
            lip = '.'.join(str(b) for b in struct.pack('<I', int(la, 16)))
            rip = '.'.join(str(b) for b in struct.pack('<I', int(ra, 16)))
            states = {'0A':'LISTEN','01':'EST'}
            print(f'{lip}:{int(lp,16)} -> {rip}:{int(rp,16)} [{states[st]}]')
" >> /build-results.txt 2>&1

echo "" >> /build-results.txt
echo "=== PROBE DONE ===" >> /build-results.txt
