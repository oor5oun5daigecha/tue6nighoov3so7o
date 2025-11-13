#!/bin/bash
# Debug script to run inside container during build

echo "=== Passenger Installation Debug ==="
echo "1. Nginx version and modules:"
nginx -V 2>&1

echo -e "\n2. All passenger files in /usr:"
find /usr -name "*passenger*" 2>/dev/null | head -20

echo -e "\n3. Nginx modules directory:"
ls -la /usr/lib/nginx/modules/ 2>/dev/null || echo "No /usr/lib/nginx/modules/"

echo -e "\n4. Passenger-specific nginx modules:"
find /usr -name "*ngx*passenger*.so" -o -name "ngx_http_passenger_module.so" 2>/dev/null

echo -e "\n5. Current passenger module config:"
cat /etc/nginx/modules-enabled/50-mod-http-passenger.conf 2>/dev/null || echo "No passenger module config"

echo -e "\n6. Passenger config check:"
passenger-config validate-install --auto 2>/dev/null || echo "Passenger config check failed"
