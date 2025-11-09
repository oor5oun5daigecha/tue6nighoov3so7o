# JRuby Testing Guide - Health Check Fix

## Recent Fix: Health Check Port Configuration

**Problem:** JRuby Passenger containers were failing health checks because they were checking the wrong port.

**Root Cause:** 
- Monitoring app listens on port **10254** (configured in `nginx.conf.erb`)
- Health checks were incorrectly targeting port **80**
- Only standalone JRuby correctly used port **8080**

**Solution Applied:**
- ✅ Fixed all Passenger container health checks to use port **10254**
- ✅ Updated all docker-compose files (`docker-compose-jruby.yaml`, `docker-compose-jruby.ci.yaml`, `docker-compose.yaml`)
- ✅ Updated all Dockerfile health checks
- ✅ Added documentation explaining port configuration

**Port Configuration:**
- **Passenger containers:** Port 10254 → `/monitus/metrics`
- **Standalone JRuby:** Port 8080 → `/health`

**To test the fix:**
```bash
cd test && make jruby-clean && make jruby-all
```

---

