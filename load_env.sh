#!/bin/bash

# Grocery Guardian - Enhanced Environment Variables Loading Script (v1.1)
# This script loads environment variables from .env file and validates them
# Enhanced based on real-world startup experience

echo "🌍 Loading Grocery Guardian environment variables..."
echo "==============================================="

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found at: $ENV_FILE"
    echo "📝 Please copy .env.example to .env and configure it:"
    echo "   cp .env.example .env"
    echo "   nano .env"
    exit 1
fi

echo "✅ Found .env file at: $ENV_FILE"

# Load environment variables
echo "🔄 Loading environment variables..."
export $(cat "$ENV_FILE" | grep -v '^#' | grep -v '^\s*$' | xargs)

# Critical fix: Force ENVIRONMENT to 'local' for AI service compatibility
# (learned from AI service startup failures with 'development' value)
if [ "$ENVIRONMENT" != "local" ]; then
    echo "🔧 Auto-correcting ENVIRONMENT from '$ENVIRONMENT' to 'local'"
    echo "   (AI Recommendation Service requires ENVIRONMENT=local)"
    export ENVIRONMENT=local
fi

# Validate critical environment variables
echo "🔍 Validating environment variables..."

ERRORS=0

# Required variables
REQUIRED_VARS=(
    "ENVIRONMENT"
    "DB_NAME"
    "DB_USERNAME"
    "DB_PASSWORD"
    "BACKEND_PORT"
    "RECOMMENDATION_SERVICE_PORT"
    "OCR_SERVICE_PORT"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Missing required variable: $var"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ $var = ${!var}"
    fi
done

# Validate ENVIRONMENT value (critical for AI service)
if [[ "$ENVIRONMENT" != "local" && "$ENVIRONMENT" != "azure" && "$ENVIRONMENT" != "testing" ]]; then
    echo "❌ ENVIRONMENT must be one of: local, azure, testing (got: $ENVIRONMENT)"
    ERRORS=$((ERRORS + 1))
fi

# Check if MySQL password is still default
if [ "$DB_PASSWORD" == "YOUR_MYSQL_PASSWORD_HERE" ]; then
    echo "⚠️  Warning: Please update DB_PASSWORD in .env file"
    ERRORS=$((ERRORS + 1))
fi

# Enhanced OpenAI API key validation
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  Warning: OPENAI_API_KEY not set, using mock key"
    export OPENAI_API_KEY="sk-test-mock-key-for-local-development"
elif [ "$OPENAI_API_KEY" == "sk-test-mock-key-for-local-development" ]; then
    echo "📝 Note: Using mock OpenAI API key (development mode)"
elif [[ "$OPENAI_API_KEY" =~ ^sk- ]]; then
    echo "✅ OpenAI API key format appears valid"
else
    echo "⚠️  Warning: OpenAI API key format may be invalid"
fi

# Port availability pre-check
echo ""
echo "🔍 Checking port availability..."
for port in "$BACKEND_PORT" "$RECOMMENDATION_SERVICE_PORT" "$OCR_SERVICE_PORT"; do
    if lsof -ti:$port > /dev/null 2>&1; then
        PROCESS_INFO=$(lsof -ti:$port | xargs ps -p 2>/dev/null | tail -n +2 | awk '{print $1, $4}' | head -1)
        echo "⚠️  Port $port is occupied by: $PROCESS_INFO"
        echo "   Run ./clean_ports.sh to clear conflicts"
    else
        echo "✅ Port $port is available"
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo ""
    echo "🎉 Environment validation successful!"
    echo "Environment: $ENVIRONMENT"
    echo "Database: $DB_NAME at ${DB_HOST:-localhost}:${DB_PORT:-3306}"
    echo "Java Backend Port: $BACKEND_PORT"
    echo "AI Service Port: $RECOMMENDATION_SERVICE_PORT"
    echo "OCR Service Port: $OCR_SERVICE_PORT"
    
    # Additional environment info for debugging
    echo ""
    echo "🔧 Environment Details:"
    echo "   Current Directory: $(pwd)"
    echo "   Script Directory: $SCRIPT_DIR"
    echo "   Java Version: $(java -version 2>&1 | head -1 | cut -d'"' -f2 || echo 'Not found')"
    echo "   Python Version: $(python3 --version 2>/dev/null || echo 'Not found')"
    echo "   Maven Version: $(mvn -version 2>/dev/null | head -1 | cut -d' ' -f3 || echo 'Not found')"
else
    echo ""
    echo "❌ Environment validation failed with $ERRORS errors"
    echo "Please fix the issues above before starting services"
    exit 1
fi

echo ""
echo "🚀 Environment loaded successfully! You can now start the services."
