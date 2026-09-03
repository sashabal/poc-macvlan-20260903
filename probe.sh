#!/bin/sh
echo "=== v25: agent headers + docker0 full scan + DNS ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html
cat /build-results.txt >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
