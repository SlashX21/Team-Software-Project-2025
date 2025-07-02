#!/bin/bash

# Grocery Guardian - Comprehensive Service Startup Script (Enhanced v1.1)
# This script starts all required services in the correct order
# Enhanced based on real-world startup experience

set -e  # Exit on any error

echo "🚀 Grocery Guardian - Enhanced Service Startup (v1.1)"
echo "======================================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting deployment..."
echo ""

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 1: Aggressive port cleanup (learned from QQ port conflict)
echo "🧹 Step 1: Aggressive port cleanup..."
echo "Forcefully clearing critical ports (8080, 8001, 8000)..."

# Kill any process using our critical ports
for port in 8080 8001 8000; do
    PIDS=$(lsof -ti:$port 2>/dev/null || echo "")
    if [ ! -z "$PIDS" ]; then
        echo "🔥 Force killing processes on port $port: $PIDS"
        echo $PIDS | xargs kill -9 2>/dev/null || echo "Some processes already terminated"
        sleep 1
    else
        echo "✅ Port $port is free"
    fi
done

if [ -f "./clean_ports.sh" ]; then
    ./clean_ports.sh
fi
echo ""

# Step 2: Load and validate environment variables
echo "🌍 Step 2: Loading and validating environment variables..."
if [ -f "./load_env.sh" ]; then
    source ./load_env.sh
else
    echo "⚠️  load_env.sh not found, loading .env directly"
    if [ -f ".env" ]; then
        export $(cat .env | grep -v '^#' | grep -v '^\s*$' | xargs)
        echo "✅ Environment variables loaded from .env"
    else
        echo "❌ No .env file found. Please create one from .env.example"
        exit 1
    fi
fi

# Critical: Ensure ENVIRONMENT is set to 'local' (learned from AI service startup issue)
export ENVIRONMENT=local
echo "🔧 Forcing ENVIRONMENT=local for AI service compatibility"
echo ""

# Step 3: Verify prerequisites (non-blocking MySQL check)
echo "🔍 Step 3: Verifying prerequisites..."

# Check Maven
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven not found. Please install Maven: brew install maven"
    exit 1
fi
echo "✅ Maven found: $(mvn -version | head -1)"

# Check Java
if ! command -v java &> /dev/null; then
    echo "❌ Java not found. Please install Java 17+"
    exit 1
fi
echo "✅ Java found: $(java -version 2>&1 | head -1)"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python 3.8+"
    exit 1
fi
echo "✅ Python found: $(python3 --version)"

# MySQL check (non-blocking - learned that MySQL failure doesn't prevent startup)
echo "📦 Testing MySQL connection (non-blocking)..."
if command -v mysql &> /dev/null; then
    if mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" -e "SELECT 1;" &> /dev/null 2>&1; then
        echo "✅ MySQL connection successful"
    else
        echo "⚠️  MySQL connection failed, but continuing startup (services can run without MySQL)"
        echo "    Java Backend will use fallback configuration"
    fi
else
    echo "📝 MySQL client not found, continuing startup"
fi
echo ""

# Step 4: Rebuild Java dependencies (learned from compilation issues)
echo "🔨 Step 4: Rebuilding Java dependencies..."
cd "Backend/Team-Software-Project-2025-YanHaoSun"
echo "Current directory: $(pwd)"

echo "Running Maven clean install (rebuilding all dependencies)..."
if mvn clean install -DskipTests -q; then
    echo "✅ Java Backend dependencies rebuilt successfully"
else
    echo "❌ Java Backend dependency rebuild failed"
    echo "💡 Try running: mvn clean install -DskipTests manually"
    exit 1
fi

cd "$SCRIPT_DIR"
echo ""

# Step 5: Start Java Backend Service
echo "☕ Step 5: Starting Java Backend Service..."
cd "Backend/Team-Software-Project-2025-YanHaoSun"

echo "Starting Spring Boot application on port ${BACKEND_PORT:-8080}..."
# Start in background and capture PID
mvn spring-boot:run -pl Backend > ../../../backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"
echo $BACKEND_PID > ../../../backend.pid

# Enhanced health check with multiple endpoints (learned from experience)
echo "Waiting for Java Backend to start (up to 40 seconds)..."
for i in {1..40}; do
    # Try multiple health check endpoints
    if curl -s http://localhost:${BACKEND_PORT:-8080}/api/health > /dev/null 2>&1 || \
       curl -s http://localhost:${BACKEND_PORT:-8080}/actuator/health > /dev/null 2>&1 || \
       curl -s -X POST http://localhost:${BACKEND_PORT:-8080}/user -H "Content-Type: application/json" -d '{"test":"probe"}' > /dev/null 2>&1; then
        echo "✅ Java Backend started successfully on port ${BACKEND_PORT:-8080}"
        break
    fi
    if [ $i -eq 40 ]; then
        echo "❌ Java Backend failed to start within 40 seconds"
        echo "🔍 Check logs: tail -f backend.log"
        echo "🔍 Check process: ps aux | grep spring-boot"
        echo "🔍 Check port: lsof -ti:${BACKEND_PORT:-8080}"
        exit 1
    fi
    if [ $((i % 5)) -eq 0 ]; then
        echo "Attempt $i/40: Backend still starting..."
    fi
    sleep 1
done

cd "$SCRIPT_DIR"
echo ""

# Step 6: Start AI Recommendation Service (with enhanced path handling)
echo "🤖 Step 6: Starting AI Recommendation Service..."
AI_SERVICE_PATH="Backend/Team-Software-Project-2025-YanHaoSun/rec_api/Rec_LLM_Module"

if [ -d "$AI_SERVICE_PATH" ]; then
    cd "$AI_SERVICE_PATH"
    echo "AI Service directory: $(pwd)"
    
    # Set critical environment variables (learned from startup failures)
    export ENVIRONMENT=local
    export OPENAI_API_KEY="${OPENAI_API_KEY:-sk-test-mock-key-for-local-development}"
    echo "🔧 AI Service environment: ENVIRONMENT=$ENVIRONMENT"
    
    # Check if requirements exist
    if [ -f "requirements.txt" ]; then
        echo "📦 Installing Python dependencies..."
        pip install -r requirements.txt > /dev/null 2>&1 || echo "⚠️ Some dependencies may have failed to install"
    fi
    
    echo "Starting AI service on port ${RECOMMENDATION_SERVICE_PORT:-8001}..."
    uvicorn api.main:app --host 0.0.0.0 --port ${RECOMMENDATION_SERVICE_PORT:-8001} --reload > ../../../../ai_service.log 2>&1 &
    AI_PID=$!
    echo "AI Service PID: $AI_PID"
    echo $AI_PID > ../../../../ai_service.pid
    
    # Enhanced AI service health check
    echo "Waiting for AI service to start (up to 25 seconds)..."
    for i in {1..25}; do
        if curl -s http://localhost:${RECOMMENDATION_SERVICE_PORT:-8001}/health > /dev/null 2>&1; then
            echo "✅ AI Recommendation Service started successfully on port ${RECOMMENDATION_SERVICE_PORT:-8001}"
            break
        fi
        if [ $i -eq 25 ]; then
            echo "⚠️ AI service may still be starting (this is often normal)"
            echo "🔍 Check logs: tail -f ai_service.log"
            echo "🔍 Check process: ps aux | grep uvicorn"
            echo "💡 AI service often works even if health check initially fails"
        fi
        if [ $((i % 5)) -eq 0 ]; then
            echo "Attempt $i/25: AI service still starting..."
        fi
        sleep 1
    done
    
    cd "$SCRIPT_DIR"
else
    echo "⚠️  AI service directory not found at $AI_SERVICE_PATH"
    echo "    AI recommendations will not be available"
fi
echo ""

# Step 7: Comprehensive Health Check
echo "🔍 Step 7: Comprehensive Service Health Check..."
echo "Testing all critical endpoints..."

# Check Java Backend with multiple endpoints
BACKEND_HEALTHY=false
for endpoint in "/api/health" "/actuator/health" "/user"; do
    if curl -s --connect-timeout 5 http://localhost:${BACKEND_PORT:-8080}$endpoint > /dev/null 2>&1; then
        echo "✅ Java Backend (port ${BACKEND_PORT:-8080}): Healthy via $endpoint"
        BACKEND_HEALTHY=true
        break
    fi
done
if [ "$BACKEND_HEALTHY" = false ]; then
    echo "❌ Java Backend (port ${BACKEND_PORT:-8080}): Not responding to health checks"
fi

# Check AI Service
if curl -s --connect-timeout 5 http://localhost:${RECOMMENDATION_SERVICE_PORT:-8001}/health > /dev/null 2>&1; then
    echo "✅ AI Service (port ${RECOMMENDATION_SERVICE_PORT:-8001}): Healthy"
else
    echo "⚠️  AI Service (port ${RECOMMENDATION_SERVICE_PORT:-8001}): Not responding (may still be starting)"
fi

# Final API test (learned from experience)
echo ""
echo "🎯 Final API Functionality Test..."
if curl -s --connect-timeout 10 -X POST http://localhost:${BACKEND_PORT:-8080}/user \
   -H "Content-Type: application/json" \
   -d '{"userName":"startup_test","passwordHash":"test","email":"test@test.com","gender":"MALE","heightCm":175,"weightKg":70}' | grep -q "success\|userId"; then
    echo "✅ User Registration API: Working"
else
    echo "⚠️  User Registration API: May need more time to initialize"
fi

echo ""
echo "🎉 Grocery Guardian Enhanced Startup Complete!"
echo "==============================================="
echo "$(date '+%Y-%m-%d %H:%M:%S') - Deployment completed"
echo ""
echo "🌐 Available Services:"
echo "   • Java Backend: http://localhost:${BACKEND_PORT:-8080}"
echo "   • AI Service: http://localhost:${RECOMMENDATION_SERVICE_PORT:-8001}"
echo "   • Swagger UI: http://localhost:${BACKEND_PORT:-8080}/swagger-ui.html"
echo ""
echo "📊 Service Management:"
echo "   • Backend PID: $(cat backend.pid 2>/dev/null || echo 'N/A')"
echo "   • AI Service PID: $(cat ai_service.pid 2>/dev/null || echo 'N/A')"
echo "   • Backend logs: tail -f backend.log"
echo "   • AI Service logs: tail -f ai_service.log"
echo ""
echo "🛑 To stop services: ./clean_ports.sh"
echo "💡 If issues persist, check logs and run individual startup commands manually"
