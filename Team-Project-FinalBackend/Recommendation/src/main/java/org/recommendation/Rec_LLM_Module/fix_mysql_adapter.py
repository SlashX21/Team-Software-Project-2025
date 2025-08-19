#!/usr/bin/env python3
"""
修复MySQL适配器中的字段名映射问题
Java数据库使用的字段名与Python期望的不同
"""

import os
import sys
from dotenv import load_dotenv

# 加载环境变量
load_dotenv('test_maven_db.env')
os.environ['ENVIRONMENT'] = 'java_integration'

from database.db_manager import MySQLAdapter
from config.settings import get_database_config
from sqlalchemy import text

def fix_mysql_adapter():
    """修复MySQL适配器的字段名映射"""
    
    print("🔧 开始修复MySQL适配器字段名映射...")
    
    config = get_database_config()
    adapter = MySQLAdapter(config)
    
    if not adapter.connect():
        print("❌ 无法连接数据库")
        return False
    
    try:
        # 测试修复后的查询
        print("\n📦 测试商品查询...")
        
        # 修复后的查询 - 使用实际的字段名，但返回Python期望的格式
        query = text("""
        SELECT 
            barcode as bar_code,
            name as product_name, 
            brand, 
            ingredients, 
            allergens,
            energy_100g, 
            energy_kcal_100g, 
            fat_100g, 
            saturated_fat_100g,
            carbohydrates_100g, 
            sugars_100g, 
            proteins_100g,
            serving_size, 
            category
        FROM product 
        WHERE category = :category
        ORDER BY name
        LIMIT :limit_val
        """)
        
        result = adapter.connection.execute(query, {"category": "Beverages", "limit_val": 5})
        products = [dict(row._mapping) for row in result.fetchall()]
        
        print(f"✅ 找到 {len(products)} 个饮料产品:")
        for product in products:
            print(f"  - {product.get('product_name', 'N/A')} ({product.get('bar_code', 'N/A')})")
        
        # 测试用户查询
        print("\n👤 测试用户查询...")
        user_query = text("""
        SELECT 
            user_id,
            username as user_name,
            email,
            age,
            gender,
            nutrition_goal,
            daily_calories_target,
            activity_level
        FROM user 
        WHERE user_id = :user_id
        """)
        
        result = adapter.connection.execute(user_query, {"user_id": 1})
        user = result.fetchone()
        
        if user:
            user_dict = dict(user._mapping)
            print(f"✅ 找到用户: {user_dict.get('user_name', 'N/A')}")
            print(f"  - 营养目标: {user_dict.get('nutrition_goal', 'N/A')}")
            print(f"  - 年龄: {user_dict.get('age', 'N/A')}")
        else:
            print("❌ 未找到用户ID=1")
        
        # 测试条码查询
        print("\n🔍 测试条码查询...")
        barcode_query = text("""
        SELECT 
            barcode as bar_code,
            name as product_name,
            brand,
            category,
            energy_kcal_100g,
            proteins_100g,
            fat_100g,
            sugars_100g
        FROM product 
        LIMIT 1
        """)
        
        result = adapter.connection.execute(barcode_query)
        product = result.fetchone()
        
        if product:
            product_dict = dict(product._mapping)
            print(f"✅ 测试产品: {product_dict.get('product_name', 'N/A')}")
            print(f"  - 条码: {product_dict.get('bar_code', 'N/A')}")
            print(f"  - 热量: {product_dict.get('energy_kcal_100g', 'N/A')} kcal/100g")
        
        print("\n🎉 字段名映射测试完成！")
        return True
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        return False
    finally:
        adapter.disconnect()

if __name__ == "__main__":
    success = fix_mysql_adapter()
    if success:
        print("\n💡 现在可以更新 database/db_manager.py 中的 MySQLAdapter 类")
        print("   使用正确的字段名映射")
    else:
        print("\n❌ 修复失败，请检查数据库连接和表结构") 