#!/bin/bash
# Debug script for JRuby + Passenger + Nginx container setup
# Author: Sketch AI Assistant

set -e

CONTAINER_NAME="jruby-passenger-debug"
IMAGE_NAME="monitus-jruby-passenger"
DEBUG_PORT=8080

echo "🔧 JRuby + Passenger + Nginx Debug Script"
echo "==========================================="
echo

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo "❌ Docker daemon is not running or not accessible"
        echo "   Please start Docker daemon and ensure current user has permissions"
        exit 1
    fi
    
    echo "✅ Docker is available"
}

# Function to build the container
build_container() {
    echo "🏗️  Building JRuby + Passenger + Nginx container..."
    echo "   Dockerfile: src/Dockerfile.jruby-passenger"
    echo "   Image name: $IMAGE_NAME"
    echo
    
    cd src
    
    echo "Building with verbose output..."
    if docker build -f Dockerfile.jruby-passenger -t $IMAGE_NAME . --progress=plain; then
        echo "✅ Container built successfully"
    else
        echo "❌ Container build failed"
        echo "🔍 Common build issues:"
        echo "   - RVM GPG key issues"
        echo "   - Network connectivity problems"
        echo "   - Ubuntu package repository issues"
        echo "   - JRuby download failures"
        echo "   - Passenger installation problems"
        return 1
    fi
    
    cd ..
}

# Function to run the container with debug settings
run_container() {
    echo "🚀 Starting JRuby + Passenger + Nginx container..."
    echo "   Container name: $CONTAINER_NAME"
    echo "   Debug port: $DEBUG_PORT"
    echo
    
    # Stop existing container if running
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    
    # Run with debug settings
    docker run -d \
        --name $CONTAINER_NAME \
        -p $DEBUG_PORT:80 \
        -e RACK_ENV=development \
        -e PASSENGER_LOG_LEVEL=3 \
        -e PASSENGER_DEBUG_MODE=true \
        -e JRUBY_OPTS="-Xcompile.invokedynamic=true --debug" \
        -e JAVA_OPTS="-Xmx1G -Xms256M -XX:+UseG1GC -Xdebug" \
        $IMAGE_NAME
    
    echo "✅ Container started"
    echo "   Access URL: http://localhost:$DEBUG_PORT"
    echo
}

# Function to check container health
check_health() {
    echo "🏥 Checking container health..."
    
    # Wait for container to start
    echo "Waiting for container to initialize (30s)..."
    sleep 30
    
    # Check if container is running
    if ! docker ps | grep -q $CONTAINER_NAME; then
        echo "❌ Container is not running"
        echo "📋 Container status:"
        docker ps -a | grep $CONTAINER_NAME || echo "Container not found"
        return 1
    fi
    
    echo "✅ Container is running"
    
    # Test health endpoint
    echo "Testing health endpoint..."
    if curl -f -s "http://localhost:$DEBUG_PORT/health" > /dev/null; then
        echo "✅ Health endpoint responding"
    else
        echo "❌ Health endpoint not responding"
        echo "   URL tested: http://localhost:$DEBUG_PORT/health"
    fi
    
    # Test metrics endpoint
    echo "Testing metrics endpoint..."
    if curl -f -s "http://localhost:$DEBUG_PORT/monitus/metrics" > /dev/null; then
        echo "✅ Metrics endpoint responding"
    else
        echo "❌ Metrics endpoint not responding"
        echo "   URL tested: http://localhost:$DEBUG_PORT/monitus/metrics"
    fi
}

# Function to show container logs
show_logs() {
    echo "📋 Container logs (last 50 lines):"
    echo "===================================="
    docker logs --tail 50 $CONTAINER_NAME
    echo
}

# Function to debug inside container
debug_inside() {
    echo "🔍 Debugging inside container..."
    echo
    
    echo "📊 Container processes:"
    docker exec $CONTAINER_NAME ps aux
    echo
    
    echo "🔧 JRuby version:"
    docker exec $CONTAINER_NAME jruby --version
    echo
    
    echo "☕ Java version:"
    docker exec $CONTAINER_NAME java -version
    echo
    
    echo "🚢 Passenger status:"
    docker exec $CONTAINER_NAME passenger-status || echo "Passenger status not available"
    echo
    
    echo "🌐 Nginx status:"
    docker exec $CONTAINER_NAME nginx -t
    docker exec $CONTAINER_NAME service nginx status || echo "Nginx service status not available"
    echo
    
    echo "📁 Application files:"
    docker exec $CONTAINER_NAME ls -la /home/app/webapp/ || echo "App directory not found"
    echo
    
    echo "🔗 Port bindings:"
    docker exec $CONTAINER_NAME netstat -tlnp | grep :80 || echo "No processes listening on port 80"
    echo
}

# Function to test endpoints
test_endpoints() {
    echo "🧪 Testing all endpoints..."
    echo
    
    BASE_URL="http://localhost:$DEBUG_PORT"
    
    # Test health
    echo "Testing $BASE_URL/health"
    if response=$(curl -s -w "HTTP %{http_code}" "$BASE_URL/health"); then
        echo "✅ Health: $response"
    else
        echo "❌ Health: Failed to connect"
    fi
    
    # Test root
    echo "Testing $BASE_URL/"
    if response=$(curl -s -w "HTTP %{http_code}" "$BASE_URL/"); then
        echo "✅ Root: $response"
    else
        echo "❌ Root: Failed to connect"
    fi
    
    # Test metrics
    echo "Testing $BASE_URL/monitus/metrics"
    if response=$(curl -s -w "HTTP %{http_code}" "$BASE_URL/monitus/metrics"); then
        echo "✅ Metrics: $response"
    else
        echo "❌ Metrics: Failed to connect"
    fi
    
    # Test passenger status endpoints
    echo "Testing $BASE_URL/monitus/passenger-status-node_json"
    if response=$(curl -s -w "HTTP %{http_code}" "$BASE_URL/monitus/passenger-status-node_json"); then
        echo "✅ Passenger Status JSON: $response"
    else
        echo "❌ Passenger Status JSON: Failed to connect"
    fi
    
    echo
}

# Function to cleanup
cleanup() {
    echo "🧹 Cleaning up..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    echo "✅ Cleanup completed"
}

# Function to interactive debug session
interactive_debug() {
    echo "🐚 Starting interactive debug session..."
    echo "   Container: $CONTAINER_NAME"
    echo "   You can now run commands inside the container"
    echo "   Type 'exit' to return to this script"
    echo
    
    docker exec -it $CONTAINER_NAME /bin/bash
}

# Main menu
show_menu() {
    echo
    echo "🔧 JRuby + Passenger + Nginx Debug Menu"
    echo "======================================"
    echo "1) Build container"
    echo "2) Run container"
    echo "3) Check health"
    echo "4) Show logs"
    echo "5) Debug inside container"
    echo "6) Test endpoints"
    echo "7) Interactive debug session"
    echo "8) Full debug cycle (build + run + test)"
    echo "9) Cleanup"
    echo "0) Exit"
    echo
    read -p "Choose option (0-9): " choice
}

# Handle menu choice
handle_choice() {
    case $choice in
        1) build_container ;;
        2) run_container ;;
        3) check_health ;;
        4) show_logs ;;
        5) debug_inside ;;
        6) test_endpoints ;;
        7) interactive_debug ;;
        8) 
            echo "🔄 Running full debug cycle..."
            build_container && 
            run_container && 
            check_health && 
            test_endpoints && 
            debug_inside
            ;;
        9) cleanup ;;
        0) 
            echo "👋 Goodbye!"
            exit 0
            ;;
        *) 
            echo "❌ Invalid option: $choice"
            ;;
    esac
}

# Main execution
echo "🔍 Checking prerequisites..."
check_docker
echo

# Command line arguments
if [ $# -eq 0 ]; then
    # Interactive mode
    while true; do
        show_menu
        handle_choice
        echo
        read -p "Press Enter to continue..."
    done
else
    # Command line mode
    case $1 in
        build) build_container ;;
        run) run_container ;;
        health) check_health ;;
        logs) show_logs ;;
        debug) debug_inside ;;
        test) test_endpoints ;;
        shell) interactive_debug ;;
        full) 
            build_container && 
            run_container && 
            check_health && 
            test_endpoints
            ;;
        cleanup) cleanup ;;
        *) 
            echo "Usage: $0 [build|run|health|logs|debug|test|shell|full|cleanup]"
            echo "   Or run without arguments for interactive mode"
            exit 1
            ;;
    esac
fi
