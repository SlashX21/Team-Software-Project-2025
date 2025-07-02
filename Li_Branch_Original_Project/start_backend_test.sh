#!/bin/bash

# Grocery Guardian Backend Test Startup Script (Enhanced)
# This script provides a simple way to start just the Java backend for testing

set -e  # Exit on any error

echo "🚀 Grocery Guardian 后端服务启动测试"
echo "====================================="
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting backend test..."
echo ""

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"

# Load environment if .env exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "📁 Loading environment variables from .env..."
    export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | grep -v '^\\s*$' | xargs)
    echo "✅ Environment loaded"
else
    echo "⚠️  No .env file found, using default settings"
    export BACKEND_PORT=8080
fi

echo ""

# Validate current directory and target path
BACKEND_DIR="$SCRIPT_DIR/Backend/Team-Software-Project-2025-YanHaoSun"
echo "🔍 Checking backend directory: $BACKEND_DIR"

if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Backend directory not found: $BACKEND_DIR"
    echo "Current directory contents:"
    ls -la "$SCRIPT_DIR"
    echo ""
    echo "Please ensure you're running this script from the project root directory."
    exit 1
fi

echo "✅ Backend directory found"

# 切换到后端目录
cd "$BACKEND_DIR"
echo "📂 Changed to directory: $(pwd)"

# 检查Maven是否可用
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven未安装或未在PATH中"
    echo "请安装Maven: brew install maven"
    exit 1
fi

echo "✅ Maven已安装: $(mvn -version | head -1)"

# 检查Java环境
echo "☕ Java版本信息:"
java -version

# Check for essential files
echo ""
echo "🔍 验证项目文件..."
if [ ! -f "pom.xml" ]; then
    echo "❌ pom.xml not found in $(pwd)"
    exit 1
fi
echo "✅ Found pom.xml"

if [ ! -d "Backend" ]; then
    echo "❌ Backend module directory not found"
    exit 1
fi
echo "✅ Found Backend module"

echo ""
echo "🔧 编译并启动后端服务..."
echo "注意: 首次启动会创建数据库表结构"
echo "端口: ${BACKEND_PORT:-8080}"

# Clean and compile first
echo "🧹 Cleaning and compiling..."
if mvn clean compile -q; then
    echo "✅ Compilation successful"
else
    echo "❌ Compilation failed"
    exit 1
fi

echo ""
echo "🚀 启动Spring Boot应用..."

# 启动后端服务
mvn spring-boot:run -pl Backend -Dspring-boot.run.args="--server.port=${BACKEND_PORT:-8080}"

echo ""
echo "🔍 服务健康检查:"
echo "- API文档: http://localhost:${BACKEND_PORT:-8080}/swagger-ui.html"
echo "- 健康检查: http://localhost:${BACKEND_PORT:-8080}/actuator/health"
echo "- 用户注册: http://localhost:${BACKEND_PORT:-8080}/user"
echo "- 数据库管理: http://localhost:${BACKEND_PORT:-8080}/h2-console (如果启用)" 