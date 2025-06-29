#!/bin/bash

echo "🔍 Grocery Guardian 数据库连接测试"
echo "=================================="

# 读取环境变量
source .env 2>/dev/null || echo "警告: .env 文件不存在"

# 设置默认值
DB_USERNAME=${DB_USERNAME:-root}
DB_PASSWORD=${DB_PASSWORD:-20020213Lx}
DB_NAME=${DB_NAME:-springboot_demo}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}

echo "📊 数据库配置信息:"
echo "  主机: $DB_HOST:$DB_PORT"
echo "  用户名: $DB_USERNAME"
echo "  数据库: $DB_NAME"
echo ""

# 测试数据库连接
echo "🔗 测试数据库连接..."
if mysql -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p$DB_PASSWORD -e "SELECT 1;" 2>/dev/null; then
    echo "✅ 数据库连接成功!"
    
    # 检查数据库是否存在
    echo ""
    echo "🗄️ 检查数据库..."
    if mysql -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p$DB_PASSWORD -e "USE $DB_NAME; SELECT 'Database exists' as status;" 2>/dev/null; then
        echo "✅ 数据库 $DB_NAME 存在"
        
        # 显示表列表
        echo ""
        echo "📋 数据库表列表:"
        mysql -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p$DB_PASSWORD -e "USE $DB_NAME; SHOW TABLES;" 2>/dev/null || echo "暂无表"
    else
        echo "❌ 数据库 $DB_NAME 不存在"
        echo "尝试创建数据库..."
        mysql -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p$DB_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null && echo "✅ 数据库创建成功" || echo "❌ 数据库创建失败"
    fi
else
    echo "❌ 数据库连接失败!"
    echo ""
    echo "🔧 可能的解决方案:"
    echo "1. 检查MySQL服务是否启动: brew services start mysql"
    echo "2. 确认用户名和密码是否正确"
    echo "3. 检查防火墙设置"
    echo "4. 尝试重置MySQL密码"
    echo ""
    echo "💡 快速测试命令:"
    echo "   mysql -u $DB_USERNAME -p$DB_PASSWORD -e 'SHOW DATABASES;'"
fi

echo ""
echo "🚀 后续步骤:"
echo "1. 如果数据库连接成功，启动后端服务"
echo "2. 启动前端应用进行测试"
echo "3. 检查API健康状态: http://localhost:8080/actuator/health" 