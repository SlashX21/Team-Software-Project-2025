#!/bin/bash

# Grocery Guardian - Enhanced Port Cleanup Script (v1.1)
# This script aggressively kills any processes running on the required ports
# Enhanced based on real-world port conflict experience (e.g., QQ occupying port 8080)

echo "🧹 Enhanced port cleanup for Grocery Guardian services..."
echo "========================================================="
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting port cleanup"
echo ""

# Define the ports used by our services
PORTS=(8080 8001 8000 3306)
PORT_NAMES=("Java Backend" "AI Recommendation Service" "OCR Service" "MySQL")

# Function to aggressively kill process on a specific port
kill_port() {
    local port=$1
    local service_name=$2
    
    echo "🔍 Checking port $port ($service_name)..."
    
    # Find all processes using the port
    PIDS=$(lsof -ti:$port 2>/dev/null)
    
    if [ -n "$PIDS" ]; then
        echo "⚠️  Found processes running on port $port:"
        
        # Show detailed process information before killing
        for PID in $PIDS; do
            PROCESS_INFO=$(ps -p $PID -o comm= 2>/dev/null || echo "Unknown")
            echo "   PID $PID: $PROCESS_INFO"
        done
        
        echo "🔪 Force killing all processes on port $port..."
        
        # Kill each process
        for PID in $PIDS; do
            # Try SIGTERM first, then SIGKILL
            if kill $PID 2>/dev/null; then
                echo "   Sent SIGTERM to PID $PID"
                sleep 1
                # Check if still running, then use SIGKILL
                if kill -0 $PID 2>/dev/null; then
                    echo "   Process $PID still running, using SIGKILL..."
                    kill -9 $PID 2>/dev/null
                fi
            else
                echo "   Process $PID may have already terminated"
            fi
        done
        
        # Verify all processes were killed
        sleep 2
        REMAINING_PIDS=$(lsof -ti:$port 2>/dev/null)
        if [ -z "$REMAINING_PIDS" ]; then
            echo "✅ Port $port is now completely free"
        else
            echo "⚠️  Some processes may still be using port $port:"
            for PID in $REMAINING_PIDS; do
                PROCESS_INFO=$(ps -p $PID -o comm= 2>/dev/null || echo "Unknown")
                echo "   Remaining PID $PID: $PROCESS_INFO"
            done
            echo "🔥 Final aggressive cleanup attempt..."
            echo $REMAINING_PIDS | xargs kill -9 2>/dev/null
            sleep 1
        fi
    else
        echo "✅ Port $port is already free"
    fi
    echo ""
}

# Function to show current port usage before cleanup
show_port_usage() {
    echo "📊 Current port usage before cleanup:"
    for i in "${!PORTS[@]}"; do
        local port="${PORTS[$i]}"
        local service="${PORT_NAMES[$i]}"
        local usage=$(lsof -ti:$port 2>/dev/null | wc -l | tr -d ' ')
        if [ "$usage" -gt 0 ]; then
            echo "   Port $port ($service): $usage process(es) detected"
        else
            echo "   Port $port ($service): Free"
        fi
    done
    echo ""
}

# Show current usage
show_port_usage

# Clean each port with aggressive approach
for i in "${!PORTS[@]}"; do
    kill_port "${PORTS[$i]}" "${PORT_NAMES[$i]}"
done

# Final verification
echo "🔍 Final verification..."
ANY_OCCUPIED=false
for i in "${!PORTS[@]}"; do
    local port="${PORTS[$i]}"
    local service="${PORT_NAMES[$i]}"
    if lsof -ti:$port > /dev/null 2>&1; then
        echo "⚠️  Port $port ($service): Still occupied"
        ANY_OCCUPIED=true
    else
        echo "✅ Port $port ($service): Confirmed free"
    fi
done

echo ""
if [ "$ANY_OCCUPIED" = true ]; then
    echo "⚠️  Some ports may still be occupied. You may need to:"
    echo "   • Restart the conflicting applications"
    echo "   • Check system processes: sudo lsof -i :PORT"
    echo "   • Reboot if issues persist"
else
    echo "🎉 All ports successfully cleaned!"
    echo "You can now start Grocery Guardian services without conflicts."
fi

echo ""
echo "💡 To start services after cleanup:"
echo "   ./start_all_services.sh"
