#!/bin/sh
echo "=== v23: TCP table dump + agent deep probe ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html
cat /build-results.txt >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
