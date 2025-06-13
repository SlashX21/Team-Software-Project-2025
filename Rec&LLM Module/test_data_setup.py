"""
快速设置测试数据
"""
import sqlite3
from datetime import datetime

def setup_test_data():
    """设置基础测试数据"""
    db_path = "data/grocery_guardian.db"
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 1. 插入测试商品
        test_products = [
            ("5449000000996", "Coca-Cola Classic 500ml", "Coca-Cola", "Beverages", 180, 0, 39, 0),
            ("7622210951717", "White Sliced Bread", "Brennans", "Food", 265, 8.5, 49, 3.2)
        ]
        
        cursor.executemany("""
            INSERT OR REPLACE INTO PRODUCT 
            (barcode, name, brand, category, energy_kcal_100g, proteins_100g, carbohydrates_100g, fat_100g)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, test_products)
        
        # 2. 插入测试用户
        cursor.execute("""
            INSERT OR REPLACE INTO USER 
            (user_id, username, email, age, gender, nutrition_goal, daily_calories_target, daily_protein_target)
            VALUES (1, 'test_user', 'test@example.com', 25, 'male', 'lose_weight', 2000, 120)
        """)
        
        # 3. 插入测试过敏原
        test_allergens = [("milk", "dairy", 1), ("nuts", "tree_nuts", 1)]
        cursor.executemany("""
            INSERT OR REPLACE INTO ALLERGEN (name, category, is_common)
            VALUES (?, ?, ?)
        """, test_allergens)
        
        conn.commit()
        conn.close()
        
        print("✅ 测试数据设置完成")
        return True
        
    except Exception as e:
        print(f"❌ 测试数据设置失败: {e}")
        return False

if __name__ == "__main__":
    setup_test_data()
