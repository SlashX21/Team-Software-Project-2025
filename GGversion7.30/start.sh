#!/bin/bash

echo "🚀 启动 Grocery Guardian 全栈应用..."

# 保存当前目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查MySQL服务
echo "📊 检查MySQL服务..."
if ! brew services list | grep mysql | grep started > /dev/null; then
    echo "启动MySQL服务..."
    brew services start mysql
else
    echo "MySQL服务已在运行"
fi

# 创建日志目录
mkdir -p logs

# 启动后端服务
echo "🔧 启动Spring Boot后端服务 (端口8080)..."
cd backend
mvn spring-boot:run -pl Backend > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
echo "后端服务PID: $BACKEND_PID"

# 等待后端启动
echo "⏳ 等待后端服务启动..."
sleep 15

# 启动推荐系统
echo "🤖 启动推荐系统服务 (端口8001)..."
cd Recommendation/src/main/java/org/recommendation/Rec_LLM_Module
source venv/bin/activate
python start_with_maven_db.py > "$SCRIPT_DIR/logs/recommendation.log" 2>&1 &
RECOMMENDATION_PID=$!
echo "推荐系统PID: $RECOMMENDATION_PID"

# 启动OCR系统
echo "📷 启动OCR系统服务 (端口8000)..."
cd "$SCRIPT_DIR/backend/Ocr/src/main/java/org/ocr/python/demo"
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 > "$SCRIPT_DIR/logs/ocr.log" 2>&1 &
OCR_PID=$!
echo "OCR系统PID: $OCR_PID"

# 启动前端应用
echo "📱 启动Flutter前端应用..."
cd "$SCRIPT_DIR/frontend/grocery_guardian_app"
flutter run -d chrome --web-port 3000 > "$SCRIPT_DIR/logs/frontend.log" 2>&1 &
FLUTTER_PID=$!
echo "Flutter应用PID: $FLUTTER_PID"

# 保存PID到文件
echo $BACKEND_PID > "$SCRIPT_DIR/logs/backend.pid"
echo $RECOMMENDATION_PID > "$SCRIPT_DIR/logs/recommendation.pid"
echo $OCR_PID > "$SCRIPT_DIR/logs/ocr.pid"
echo $FLUTTER_PID > "$SCRIPT_DIR/logs/flutter.pid"

echo ""
echo "✅ 所有服务已启动!"
echo ""
echo "📋 服务状态:"
echo "   🔧 后端服务: http://localhost:8080"
echo "   🤖 推荐系统: http://localhost:8001"
echo "   📷 OCR系统: http://localhost:8000"
echo "   📱 Flutter应用: http://localhost:3000"
echo ""
echo "📁 日志文件位置:"
echo "   backend.log: logs/backend.log"
echo "   recommendation.log: logs/recommendation.log"
echo "   ocr.log: logs/ocr.log"
echo "   frontend.log: logs/frontend.log"
echo ""
echo "🛑 停止所有服务: ./stop.sh" 