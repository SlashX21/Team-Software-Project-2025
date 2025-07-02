#!/usr/bin/env python3
"""
启动推荐系统API服务 - 连接Maven数据库
"""

import os
import sys
import subprocess
from dotenv import load_dotenv

def main():
    """主函数"""
    print("🚀 启动Grocery Guardian推荐系统API...")
    print("📊 使用Maven Liquibase数据库")
    print("=" * 60)
    
    # 加载环境变量
    load_dotenv('test_maven_db.env')
    
    # 设置环境变量
    os.environ['ENVIRONMENT'] = 'java_integration'
    
    # 检查必要的环境变量
    required_vars = ['JAVA_DB_CONNECTION_STRING', 'DB_TYPE']
    missing_vars = []
    
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print(f"❌ 缺少环境变量: {', '.join(missing_vars)}")
        print("请检查 test_maven_db.env 文件配置")
        return False
    
    print("✅ 环境配置检查通过")
    print(f"📊 数据库类型: {os.getenv('DB_TYPE')}")
    print(f"🔗 数据库连接: {os.getenv('JAVA_DB_CONNECTION_STRING')}")
    print("=" * 60)
    
    try:
        # 启动uvicorn服务
        cmd = [
            sys.executable, "-m", "uvicorn", 
            "api.main:app",
            "--host", "0.0.0.0",
            "--port", "8001",
            "--reload"
        ]
        
        print("🌟 启动API服务...")
        print("🔗 API文档地址: http://localhost:8001/docs")
        print("❤️  健康检查: http://localhost:8001/health")
        print("💡 按 Ctrl+C 停止服务")
        print("=" * 60)
        
        # 启动服务
        subprocess.run(cmd, env=os.environ)
        
    except KeyboardInterrupt:
        print("\n👋 服务已停止")
    except Exception as e:
        print(f"❌ 启动失败: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 