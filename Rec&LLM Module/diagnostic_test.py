"""
快速诊断Grocery Guardian模块导入问题
"""
import sys
import os
from pathlib import Path

print("🔍 Grocery Guardian 诊断测试")
print("="*50)

# 1. 检查当前工作目录
print(f"📁 当前工作目录: {os.getcwd()}")
print(f"📁 Python路径: {sys.executable}")
print(f"📋 Python版本: {sys.version}")

# 2. 检查项目结构
print("\n📂 项目结构检查:")
required_dirs = [
    "config",
    "database", 
    "recommendation",
    "llm_evaluation",
    "data"
]

for dir_name in required_dirs:
    exists = os.path.exists(dir_name)
    status = "✅" if exists else "❌"
    print(f"   {status} {dir_name}/")

# 3. 检查关键文件
print("\n📄 关键文件检查:")
required_files = [
    "config/settings.py",
    "config/constants.py", 
    "database/db_manager.py",
    "recommendation/recommender.py",
    "data/grocery_guardian.db",
    ".env"
]

for file_path in required_files:
    exists = os.path.exists(file_path)
    status = "✅" if exists else "❌"
    print(f"   {status} {file_path}")

# 4. 尝试基础导入
print("\n🔧 模块导入测试:")
import_tests = [
    ("config.settings", "get_database_config"),
    ("config.constants", "NutritionGoal"),
    ("database.db_manager", "DatabaseManager"),
]

for module_name, item_name in import_tests:
    try:
        module = __import__(module_name, fromlist=[item_name])
        getattr(module, item_name)
        print(f"   ✅ {module_name}.{item_name}")
    except Exception as e:
        print(f"   ❌ {module_name}.{item_name} - {e}")

# 5. 检查环境变量
print("\n🔑 环境变量检查:")
env_vars = ["OPENAI_API_KEY"]
for var in env_vars:
    value = os.getenv(var)
    if value:
        print(f"   ✅ {var} = {value[:10]}...***")
    else:
        print(f"   ❌ {var} 未设置")

# 6. 测试数据库连接
print("\n🗄️ 数据库连接测试:")
try:
    import sqlite3
    db_path = "data/grocery_guardian.db"
    if os.path.exists(db_path):
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM PRODUCT")
        product_count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM USER") 
        user_count = cursor.fetchone()[0]
        conn.close()
        print(f"   ✅ 数据库连接成功")
        print(f"   📊 商品数量: {product_count}")
        print(f"   👥 用户数量: {user_count}")
    else:
        print(f"   ❌ 数据库文件不存在: {db_path}")
except Exception as e:
    print(f"   ❌ 数据库连接失败: {e}")

print("\n" + "="*50)
print("🎯 诊断完成！请查看上述结果找出问题所在。")