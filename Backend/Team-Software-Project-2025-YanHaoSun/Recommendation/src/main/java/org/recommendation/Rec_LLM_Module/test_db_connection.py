#!/usr/bin/env python3
"""
数据库连接测试脚本
测试Python推荐系统是否能够连接到Maven Liquibase数据库
"""

import os
import sys
from dotenv import load_dotenv

# 加载环境变量
load_dotenv('test_maven_db.env')

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config.settings import ConfigManager, DatabaseConfig
from database.db_manager import DatabaseManager

def test_database_connection():
    """测试数据库连接"""
    print("🔧 开始测试Maven数据库连接...")
    
    try:
        # 初始化配置管理器
        config_manager = ConfigManager("java_integration")
        db_config = config_manager.get_database_config()
        
        print(f"📊 数据库类型: {db_config.type}")
        print(f"🔗 连接字符串: {db_config.connection_string}")
        
        # 创建数据库管理器
        with DatabaseManager() as db:
            print("✅ 数据库连接成功！")
            
            # 测试基础查询
            print("\n📋 测试基础表查询...")
            
            # 测试用户表
            try:
                from sqlalchemy import text
                users = db.adapter.connection.execute(text("SELECT COUNT(*) as count FROM user")).fetchone()
                print(f"👥 用户表记录数: {users.count}")
            except Exception as e:
                print(f"⚠️  用户表查询失败: {e}")
            
            # 测试产品表
            try:
                from sqlalchemy import text
                products = db.adapter.connection.execute(text("SELECT COUNT(*) as count FROM product")).fetchone()
                print(f"📦 产品表记录数: {products.count}")
            except Exception as e:
                print(f"⚠️  产品表查询失败: {e}")
            
            # 测试过敏原表
            try:
                from sqlalchemy import text
                allergens = db.adapter.connection.execute(text("SELECT COUNT(*) as count FROM allergen")).fetchone()
                print(f"🚨 过敏原表记录数: {allergens.count}")
            except Exception as e:
                print(f"⚠️  过敏原表查询失败: {e}")
            
            # 测试表结构
            print("\n🏗️  测试表结构...")
            try:
                from sqlalchemy import text
                # 查看product表结构
                columns = db.adapter.connection.execute(text("DESCRIBE product")).fetchall()
                print("📦 Product表字段:")
                for col in columns:
                    print(f"  - {col.Field}: {col.Type}")
            except Exception as e:
                print(f"⚠️  表结构查询失败: {e}")
            
            print("\n🎉 数据库连接测试完成！")
            return True
            
    except Exception as e:
        print(f"❌ 数据库连接失败: {e}")
        print(f"错误详情: {type(e).__name__}: {str(e)}")
        return False

def test_recommendation_engine():
    """测试推荐引擎是否能正常工作"""
    print("\n🤖 测试推荐引擎...")
    
    try:
        from recommendation.recommender import get_recommendation_engine
        
        # 获取推荐引擎实例
        rec_engine = get_recommendation_engine()
        print("✅ 推荐引擎初始化成功！")
        
        # 这里可以添加更多推荐功能测试
        return True
        
    except Exception as e:
        print(f"❌ 推荐引擎测试失败: {e}")
        return False

def main():
    """主函数"""
    print("🚀 开始测试Python推荐系统与Maven数据库的连接...")
    print("=" * 60)
    
    # 检查环境变量
    print("🔍 检查环境配置...")
    required_env_vars = ['DB_TYPE', 'JAVA_DB_CONNECTION_STRING']
    missing_vars = []
    
    for var in required_env_vars:
        value = os.getenv(var)
        if not value:
            missing_vars.append(var)
        else:
            print(f"✅ {var}: {value}")
    
    if missing_vars:
        print(f"❌ 缺少环境变量: {', '.join(missing_vars)}")
        print("请检查 test_maven_db.env 文件配置")
        return False
    
    print("=" * 60)
    
    # 测试数据库连接
    db_success = test_database_connection()
    
    if db_success:
        # 测试推荐引擎
        rec_success = test_recommendation_engine()
        
        if rec_success:
            print("\n🎉 所有测试通过！推荐系统可以正常连接Maven数据库。")
            print("💡 您现在可以启动API服务:")
            print("   ENVIRONMENT=java_integration uvicorn api.main:app --host 0.0.0.0 --port 8000")
            return True
        else:
            print("\n⚠️  数据库连接正常，但推荐引擎存在问题。")
            return False
    else:
        print("\n❌ 数据库连接失败，请检查配置和数据库状态。")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 