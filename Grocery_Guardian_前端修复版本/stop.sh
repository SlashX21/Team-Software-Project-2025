#!/bin/bash

echo "🛑 停止 Grocery Guardian 全栈应用..."

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "项目根目录: $PROJECT_ROOT"

# 创建logs目录
mkdir -p "$PROJECT_ROOT/logs"

# 停止后端服务
if [ -f "$PROJECT_ROOT/logs/backend.pid" ]; then
    BACKEND_PID=$(cat "$PROJECT_ROOT/logs/backend.pid")
    if kill -0 $BACKEND_PID 2>/dev/null; then
        echo "停止后端服务 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID
    else
        echo "后端服务已停止"
    fi
    rm -f "$PROJECT_ROOT/logs/backend.pid"
fi

# 停止推荐系统
if [ -f "$PROJECT_ROOT/logs/recommendation.pid" ]; then
    RECOMMENDATION_PID=$(cat "$PROJECT_ROOT/logs/recommendation.pid")
    if kill -0 $RECOMMENDATION_PID 2>/dev/null; then
        echo "停止推荐系统 (PID: $RECOMMENDATION_PID)..."
        kill $RECOMMENDATION_PID
    else
        echo "推荐系统已停止"
    fi
    rm -f "$PROJECT_ROOT/logs/recommendation.pid"
fi

# 停止OCR系统
if [ -f "$PROJECT_ROOT/logs/ocr.pid" ]; then
    OCR_PID=$(cat "$PROJECT_ROOT/logs/ocr.pid")
    if kill -0 $OCR_PID 2>/dev/null; then
        echo "停止OCR系统 (PID: $OCR_PID)..."
        kill $OCR_PID
    else
        echo "OCR系统已停止"
    fi
    rm -f "$PROJECT_ROOT/logs/ocr.pid"
fi

# 停止Flutter应用
if [ -f "$PROJECT_ROOT/logs/flutter.pid" ]; then
    FLUTTER_PID=$(cat "$PROJECT_ROOT/logs/flutter.pid")
    if kill -0 $FLUTTER_PID 2>/dev/null; then
        echo "停止Flutter应用 (PID: $FLUTTER_PID)..."
        kill $FLUTTER_PID
    else
        echo "Flutter应用已停止"
    fi
    rm -f "$PROJECT_ROOT/logs/flutter.pid"
fi

# 强制停止可能残留的进程
echo "清理残留进程..."
pkill -f "spring-boot:run" 2>/dev/null
pkill -f "uvicorn main:app" 2>/dev/null
pkill -f "start_with_maven_db.py" 2>/dev/null
pkill -f "flutter run" 2>/dev/null

echo "✅ 所有服务已停止!" 