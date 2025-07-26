#!/bin/bash

echo "🔄 重启推荐系统服务..."

# 停止现有推荐服务
echo "⏹️  停止现有推荐服务..."
pkill -f "uvicorn.*8001"
sleep 2

# 检查端口是否释放
if lsof -i :8001 > /dev/null 2>&1; then
    echo "❌ 端口8001仍被占用，强制停止..."
    kill -9 $(lsof -t -i:8001) 2>/dev/null || true
    sleep 1
fi

# 启动新的推荐服务
echo "🚀 启动新的推荐服务..."
cd Recommendation/src/main/java/org/recommendation/Rec_LLM_Module
python3 start_with_maven_db.py &

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
if curl -s http://localhost:8001/health > /dev/null 2>&1; then
    echo "✅ 推荐服务重启成功！"
    echo "🔗 API文档: http://localhost:8001/docs"
else
    echo "❌ 推荐服务启动失败"
    exit 1
fi 