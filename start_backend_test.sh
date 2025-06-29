#!/bin/bash

echo "🚀 Grocery Guardian 后端服务启动测试"
echo "====================================="

# 切换到后端目录
cd Backend/Team-Software-Project-2025-YanHaoSun

# 检查Maven是否可用
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven未安装或未在PATH中"
    echo "请安装Maven: brew install maven"
    exit 1
fi

echo "✅ Maven已安装"

# 检查Java环境
echo "☕ Java版本信息:"
java -version

echo ""
echo "🔧 编译并启动后端服务..."
echo "注意: 首次启动会创建数据库表结构"

# 启动后端服务
mvn spring-boot:run -pl Backend

echo ""
echo "🔍 服务健康检查:"
echo "- API文档: http://localhost:8080/swagger-ui.html"
echo "- 健康检查: http://localhost:8080/actuator/health"
echo "- 数据库管理: http://localhost:8080/h2-console (如果启用)" 