#!/bin/bash
# Quick test script to debug Passenger module loading

echo "=== Testing Passenger module detection ==="

# Simulate the module search
echo "Searching for nginx passenger modules..."
PASSENGER_MODULE=$(find /usr -name "*ngx*passenger*.so" -o -name "mod_passenger.so" 2>/dev/null | head -1)

if [ -n "$PASSENGER_MODULE" ]; then
    echo "Found Passenger nginx module at: $PASSENGER_MODULE"
    echo "File info:"
    ls -la "$PASSENGER_MODULE"
else
    echo "No specific nginx passenger module found"
fi

# Check if passenger is built into nginx
echo -e "\n=== Checking if Passenger is built into nginx ==="
if which nginx >/dev/null 2>&1; then
    nginx -V 2>&1 | grep -i passenger && echo "Passenger is built-in" || echo "Passenger not built-in"
else
    echo "nginx not found"
fi

# List all passenger-related files
echo -e "\n=== All passenger files ==="
find /usr -name "*passenger*" 2>/dev/null | head -10
