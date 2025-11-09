#!/bin/bash
# Configuration diagnostics for JRuby + Passenger + Nginx setup
# Author: Sketch AI Assistant

set -e

echo "🔍 JRuby + Passenger + Nginx Configuration Diagnostics"
echo "======================================================="
echo

# Function to analyze Dockerfile
analyze_dockerfile() {
    echo "📄 Analyzing Dockerfile.jruby-passenger:"
    echo "=========================================="
    
    local dockerfile="src/Dockerfile.jruby-passenger"
    
    if [ -f "$dockerfile" ]; then
        echo "✅ Dockerfile found: $dockerfile"
        
        # Check base image
        base_image=$(grep "^FROM" "$dockerfile" | head -1 | awk '{print $2}')
        echo "📦 Base image: $base_image"
        
        # Check JRuby installation method
        if grep -q "RVM" "$dockerfile"; then
            echo "🔧 JRuby installation: RVM-based"
            rvm_version=$(grep -o "jruby-[0-9]\+\.[0-9]\+\.[0-9]\+" "$dockerfile" | head -1)
            echo "   JRuby version: ${rvm_version:-'not specified'}"
        elif grep -q "jruby:" "$dockerfile"; then
            echo "🔧 JRuby installation: Official Docker image"
        else
            echo "⚠️  JRuby installation method unclear"
        fi
        
        # Check Passenger installation
        if grep -q "passenger" "$dockerfile"; then
            echo "🚢 Passenger: Included in build"
        else
            echo "⚠️  Passenger: Not found in Dockerfile"
        fi
        
        # Check Nginx installation
        if grep -q "nginx" "$dockerfile"; then
            echo "🌐 Nginx: Included in build"
        else
            echo "⚠️  Nginx: Not found in Dockerfile"
        fi
        
        # Check environment variables
        echo "🌍 Environment variables:"
        grep "^ENV" "$dockerfile" | while read line; do
            echo "   $line"
        done
        
    else
        echo "❌ Dockerfile not found: $dockerfile"
    fi
    
    echo
}

# Function to analyze Nginx configuration
analyze_nginx_config() {
    echo "🌐 Analyzing Nginx Configuration:"
    echo "================================"
    
    local nginx_config="src/nginx-jruby.conf"
    
    if [ -f "$nginx_config" ]; then
        echo "✅ Nginx config found: $nginx_config"
        
        # Check listen directive
        listen_port=$(grep "listen" "$nginx_config" | grep -o "[0-9]\+" | head -1)
        echo "🔌 Listen port: ${listen_port:-'not found'}"
        
        # Check passenger settings
        echo "🚢 Passenger settings:"
        grep "passenger_" "$nginx_config" | while read line; do
            echo "   $line"
        done
        
        # Check root directory
        root_dir=$(grep "root" "$nginx_config" | grep -v "#" | head -1 | awk '{print $2}' | tr -d ';')
        echo "📁 Document root: ${root_dir:-'not found'}"
        
        # Check location blocks
        echo "🗺 Location blocks:"
        grep -n "location" "$nginx_config" | while read line; do
            echo "   Line ${line%%:*}: ${line#*:}"
        done
        
    else
        echo "❌ Nginx config not found: $nginx_config"
    fi
    
    echo
}

# Function to analyze Passenger configuration
analyze_passenger_config() {
    echo "🚢 Analyzing Passenger Configuration:"
    echo "==================================="
    
    local passenger_config="src/passenger-jruby.conf"
    
    if [ -f "$passenger_config" ]; then
        echo "✅ Passenger config found: $passenger_config"
        
        # Check Ruby interpreter
        ruby_path=$(grep "passenger_ruby" "$passenger_config" | head -1 | awk '{print $2}' | tr -d ';')
        echo "🔶 Ruby interpreter: ${ruby_path:-'not specified'}"
        
        # Check concurrency model
        concurrency=$(grep "passenger_concurrency_model" "$passenger_config" | head -1 | awk '{print $2}' | tr -d ';')
        echo "🧠 Concurrency model: ${concurrency:-'not specified'}"
        
        # Check thread count
        thread_count=$(grep "passenger_thread_count" "$passenger_config" | head -1 | awk '{print $2}' | tr -d ';')
        echo "🧵 Thread count: ${thread_count:-'not specified'}"
        
        # Check instance limits
        min_instances=$(grep "passenger_min_instances" "$passenger_config" | head -1 | awk '{print $2}' | tr -d ';')
        max_instances=$(grep "passenger_max_instances_per_app" "$passenger_config" | head -1 | awk '{print $2}' | tr -d ';')
        echo "📊 Instance limits: ${min_instances:-'?'} - ${max_instances:-'?'}"
        
        # Check memory limit
        memory_limit=$(grep "passenger_memory_limit" "$passenger_config" | head -1 | awk '{print $2}' | tr -d ';')
        echo "💾 Memory limit: ${memory_limit:-'not specified'} MB"
        
        # Check environment variables
        echo "🌍 Passenger environment variables:"
        grep "passenger_env_var" "$passenger_config" | while read line; do
            echo "   $line"
        done
        
    else
        echo "❌ Passenger config not found: $passenger_config"
    fi
    
    echo
}

# Function to analyze application configuration
analyze_app_config() {
    echo "🎆 Analyzing Application Configuration:"
    echo "===================================="
    
    # Check config.ru files
    echo "📄 Config.ru files:"
    find src/ -name "config.ru*" -type f | while read file; do
        echo "   ✅ $file"
        if [ "$(basename $file)" = "config.ru.jruby" ]; then
            echo "      ⭐ JRuby-specific configuration"
        fi
    done
    
    # Check Gemfiles
    echo "💎 Gemfile configurations:"
    find src/ -name "Gemfile*" -type f | while read file; do
        echo "   ✅ $file"
        if [ "$(basename $file)" = "Gemfile.jruby" ]; then
            echo "      ⭐ JRuby-specific gems"
            # Count JRuby-specific gems
            jruby_gems=$(grep -c "platforms.*jruby" "$file" 2>/dev/null || echo 0)
            echo "      🔥 JRuby platform gems: $jruby_gems"
        fi
    done
    
    # Check main application file
    local app_file="src/prometheus_exporter.rb"
    if [ -f "$app_file" ]; then
        echo "✅ Main app file: $app_file"
        
        # Check for JRuby-specific code
        if grep -q "JRUBY_VERSION" "$app_file"; then
            echo "      🔥 Contains JRuby-specific code"
        fi
        
        # Check for Sinatra
        if grep -q "Sinatra" "$app_file"; then
            echo "      🎵 Uses Sinatra framework"
        fi
        
        # Check for Prometheus client
        if grep -q "prometheus" "$app_file"; then
            echo "      📈 Uses Prometheus client"
        fi
    else
        echo "❌ Main app file not found: $app_file"
    fi
    
    echo
}

# Function to check for common issues
check_common_issues() {
    echo "⚠️  Checking for Common Issues:"
    echo "============================"
    
    local issues_found=0
    
    # Check for MRI-specific gems in JRuby Gemfile
    if [ -f "src/Gemfile.jruby" ]; then
        if grep -q "thin" "src/Gemfile.jruby"; then
            echo "❌ Issue: 'thin' gem found in JRuby Gemfile (incompatible)"
            issues_found=$((issues_found + 1))
        fi
        
        if grep -q "eventmachine" "src/Gemfile.jruby"; then
            echo "⚠️  Warning: 'eventmachine' gem may cause issues with JRuby"
        fi
        
        if ! grep -q "jruby-openssl" "src/Gemfile.jruby"; then
            echo "📝 Recommendation: Add 'jruby-openssl' gem for better SSL performance"
        fi
        
        if ! grep -q "jrjackson" "src/Gemfile.jruby"; then
            echo "📝 Recommendation: Add 'jrjackson' gem for faster JSON processing"
        fi
    fi
    
    # Check for conflicting Gemfile.lock
    if [ -f "src/Gemfile.lock" ]; then
        echo "⚠️  Warning: Gemfile.lock found - may conflict with JRuby dependencies"
        if grep -q "thin" "src/Gemfile.lock"; then
            echo "❌ Issue: Gemfile.lock contains 'thin' dependency (JRuby incompatible)"
            issues_found=$((issues_found + 1))
        fi
    fi
    
    # Check for proper Passenger spawn method
    if [ -f "src/passenger-jruby.conf" ]; then
        if ! grep -q "passenger_spawn_method.*direct" "src/passenger-jruby.conf"; then
            echo "❌ Issue: Passenger should use 'direct' spawn method for JRuby"
            issues_found=$((issues_found + 1))
        fi
    fi
    
    # Check for proper concurrency model
    if [ -f "src/passenger-jruby.conf" ]; then
        if ! grep -q "passenger_concurrency_model.*thread" "src/passenger-jruby.conf"; then
            echo "⚠️  Warning: Passenger should use 'thread' concurrency model for JRuby"
        fi
    fi
    
    # Check for reasonable thread counts
    if [ -f "src/passenger-jruby.conf" ]; then
        thread_count=$(grep "passenger_thread_count" "src/passenger-jruby.conf" | awk '{print $2}' | tr -d ';')
        if [ -n "$thread_count" ] && [ "$thread_count" -lt 8 ]; then
            echo "⚠️  Warning: Thread count ($thread_count) is quite low for JRuby"
        elif [ -n "$thread_count" ] && [ "$thread_count" -gt 64 ]; then
            echo "⚠️  Warning: Thread count ($thread_count) may be too high"
        fi
    fi
    
    if [ $issues_found -eq 0 ]; then
        echo "✅ No critical issues found!"
    else
        echo "❌ Found $issues_found critical issues that need attention"
    fi
    
    echo
}

# Function to show recommendations
show_recommendations() {
    echo "📝 Recommendations for Optimal JRuby + Passenger + Nginx Setup:"
    echo "============================================================="
    echo
    echo "1. 🔥 JRuby Optimization:"
    echo "   - Use JRUBY_OPTS='-Xcompile.invokedynamic=true'"
    echo "   - Set JAVA_OPTS='-Xmx1G -Xms256M -XX:+UseG1GC'"
    echo "   - Consider --server flag for production"
    echo
    echo "2. 🚢 Passenger Configuration:"
    echo "   - passenger_spawn_method direct (JRuby doesn't support forking)"
    echo "   - passenger_concurrency_model thread"
    echo "   - passenger_thread_count 16-32 (leverage JRuby threading)"
    echo "   - passenger_min_instances 2-4"
    echo "   - passenger_max_instances 8-16"
    echo
    echo "3. 🌐 Nginx Settings:"
    echo "   - Enable gzip compression"
    echo "   - Set appropriate worker_processes"
    echo "   - Configure static asset caching"
    echo "   - Add security headers"
    echo
    echo "4. 💎 Gem Selection:"
    echo "   - Use 'jruby-openssl' for SSL performance"
    echo "   - Use 'jrjackson' for JSON processing"
    echo "   - Avoid 'thin', 'unicorn', 'eventmachine'"
    echo "   - Use 'puma' if standalone server needed"
    echo
    echo "5. 🔍 Monitoring:"
    echo "   - Enable Passenger status endpoints"
    echo "   - Monitor JVM heap usage"
    echo "   - Track thread pool utilization"
    echo "   - Monitor request queue depth"
    echo
}

# Main execution
analyze_dockerfile
analyze_nginx_config
analyze_passenger_config
analyze_app_config
check_common_issues
show_recommendations

echo "🎆 Configuration analysis complete!"
echo "🚀 Ready to build and test with: ./debug-jruby-passenger.sh"
