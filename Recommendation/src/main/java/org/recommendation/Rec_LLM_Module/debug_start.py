#!/usr/bin/env python3
"""
调试启动脚本 - 显示详细的启动过程
"""

import os
import sys
from dotenv import load_dotenv

# 加载环境变量
load_dotenv('test_maven_db.env')

# 设置环境变量
os.environ['ENVIRONMENT'] = 'java_integration'

print("🚀 开始启动推荐系统API...")
print("=" * 60)

# 检查环境变量
print("🔍 环境变量检查:")
print(f"  ENVIRONMENT: {os.environ.get('ENVIRONMENT')}")
print(f"  DB_TYPE: {os.environ.get('DB_TYPE')}")
print(f"  JAVA_DB_CONNECTION_STRING: {os.environ.get('JAVA_DB_CONNECTION_STRING')}")
print(f"  OPENAI_API_KEY: {'已设置' if os.environ.get('OPENAI_API_KEY') else '未设置'}")

try:
    print("\n🔧 测试配置加载...")
    from config.settings import ConfigManager
    config_manager = ConfigManager("java_integration")
    db_config = config_manager.get_database_config()
    print(f"✅ 数据库配置加载成功: {db_config.type}")
    
    print("\n🗄️ 测试数据库连接...")
    from database.db_manager import DatabaseManager
    with DatabaseManager() as db:
        print("✅ 数据库连接成功")
    
    print("\n🤖 测试推荐引擎...")
    from recommendation.recommender import get_recommendation_engine
    rec_engine = get_recommendation_engine()
    print("✅ 推荐引擎初始化成功")
    
    print("\n🌟 启动FastAPI服务...")
    from api.main import app
    import uvicorn
    
    print("🔗 API服务地址:")
    print("  - 健康检查: http://localhost:8001/health")
    print("  - API文档: http://localhost:8001/docs")
    print("  - 条码推荐: POST http://localhost:8001/recommendations/barcode")
    print("  - 小票分析: POST http://localhost:8001/recommendations/receipt")
    print("=" * 60)
    print("💡 按 Ctrl+C 停止服务")
    print("=" * 60)
    
    # 启动服务
    api_port = int(os.getenv('API_PORT', 8001))
    uvicorn.run(app, host="0.0.0.0", port=api_port, log_level="info")
    
except Exception as e:
    print(f"❌ 启动失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1) 