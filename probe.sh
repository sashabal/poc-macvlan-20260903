#!/bin/sh
echo "=== v16: include bypass + network_mode:host ===" > /app/index.html
echo "Waiting for scout results..." >> /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html

# Wait for scout to write results (max 120s)
WAIT=0
while [ ! -f /scout/results.txt ] && [ $WAIT -lt 120 ]; do
  sleep 2
  WAIT=$((WAIT+2))
done

if [ -f /scout/results.txt ]; then
  echo "" >> /app/index.html
  echo "=== SCOUT RESULTS (network_mode:host) ===" >> /app/index.html
  cat /scout/results.txt >> /app/index.html
else
  echo "" >> /app/index.html
  echo "=== SCOUT TIMEOUT (no results after 120s) ===" >> /app/index.html
  echo "fragment.yml with network_mode:host may have been blocked" >> /app/index.html
fi

echo "" >> /app/index.html
echo "=== APP INFO ===" >> /app/index.html
echo "App interfaces:" >> /app/index.html
ip -4 addr show >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "App routes:" >> /app/index.html
ip route show >> /app/index.html 2>&1
echo "" >> /app/index.html
echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html

cd /app && python3 -m http.server 8080
