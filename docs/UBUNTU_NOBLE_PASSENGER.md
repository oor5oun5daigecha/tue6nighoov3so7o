# Passenger + Ubuntu Noble (24.04) Setup

## Issue

The package `libnginx-mod-http-passenger` is not available in Ubuntu Noble (24.04 LTS).

## Solution

Use the official Phusion Passenger APT repository instead:

```bash
# Add Passenger repository
curl https://oss-binaries.phusionpassenger.com/auto-software-signing-gpg-key.txt | \
  gpg --dearmor | tee /etc/apt/trusted.gpg.d/phusion.gpg >/dev/null

echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger noble main' > \
  /etc/apt/sources.list.d/passenger.list

# Update package list and install
apt-get update
apt-get install -y nginx-extras passenger
```

## Module Configuration

The Passenger module location may vary, so we dynamically find and configure it:

```bash
# Find the Passenger module
PASSENGER_MODULE=$(find /usr -name "*passenger*.so" 2>/dev/null | head -1)

if [ -n "$PASSENGER_MODULE" ]; then
    echo "load_module $PASSENGER_MODULE;" > /etc/nginx/modules-enabled/50-mod-http-passenger.conf
fi
```

## JRuby-specific Configuration

For JRuby applications with Passenger:

```nginx
passenger_enabled on;
passenger_ruby /usr/bin/jruby;
passenger_spawn_method direct;  # Critical: JRuby doesn't support fork()
passenger_app_env production;
```

## Files Modified

- `src/Dockerfile.jruby-passenger`: Updated Passenger installation method
- `docker-compose.jruby-passenger-debug.yml`: Removed obsolete version field

## Testing

Build and run the container:

```bash
docker compose -f docker-compose.jruby-passenger-debug.yml up --build
```

Check health:

```bash
curl http://localhost:8080/health
```
