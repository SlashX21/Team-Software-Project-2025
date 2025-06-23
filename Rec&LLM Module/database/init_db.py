"""
数据库初始化脚本
创建必要的表和测试数据
"""

import sqlite3
import os
from datetime import datetime

def init_database():
    """初始化数据库"""
    # 确保数据目录存在
    os.makedirs("data", exist_ok=True)
    
    # 连接数据库
    conn = sqlite3.connect("data/grocery_guardian.db")
    cursor = conn.cursor()
    
    # 创建用户表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS USER (
        user_id INTEGER PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT UNIQUE,
        age INTEGER,
        gender TEXT,
        height_cm REAL,
        weight_kg REAL,
        activity_level TEXT,
        nutrition_goal TEXT,
        daily_calories_target INTEGER,
        daily_protein_target INTEGER,
        daily_carb_target INTEGER,
        daily_fat_target INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)
    
    # 创建商品表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS PRODUCT (
        barcode TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT,
        ingredients TEXT,
        allergens TEXT,
        energy_100g REAL,
        energy_kcal_100g REAL,
        fat_100g REAL,
        saturated_fat_100g REAL,
        carbohydrates_100g REAL,
        sugars_100g REAL,
        proteins_100g REAL,
        serving_size TEXT,
        category TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)
    
    # 创建过敏原表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS ALLERGEN (
        allergen_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        is_common BOOLEAN,
        description TEXT
    )
    """)
    
    # 创建用户过敏原关联表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS USER_ALLERGEN (
        user_allergen_id INTEGER PRIMARY KEY,
        user_id INTEGER,
        allergen_id INTEGER,
        severity_level INTEGER,
        confirmed BOOLEAN,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES USER(user_id),
        FOREIGN KEY (allergen_id) REFERENCES ALLERGEN(allergen_id)
    )
    """)
    
    # 创建商品过敏原关联表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS PRODUCT_ALLERGEN (
        product_allergen_id INTEGER PRIMARY KEY,
        barcode TEXT,
        allergen_id INTEGER,
        presence_type TEXT,
        confidence_score REAL,
        FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode),
        FOREIGN KEY (allergen_id) REFERENCES ALLERGEN(allergen_id)
    )
    """)
    
    # 创建购买记录表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS PURCHASE_RECORD (
        purchase_id INTEGER PRIMARY KEY,
        user_id INTEGER,
        receipt_date TIMESTAMP,
        store_name TEXT,
        total_amount REAL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES USER(user_id)
    )
    """)
    
    # 创建购买商品表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS PURCHASE_ITEM (
        item_id INTEGER PRIMARY KEY,
        purchase_id INTEGER,
        barcode TEXT,
        item_name_ocr TEXT,
        quantity INTEGER,
        unit_price REAL,
        total_price REAL,
        FOREIGN KEY (purchase_id) REFERENCES PURCHASE_RECORD(purchase_id),
        FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode)
    )
    """)
    
    # 创建推荐日志表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS RECOMMENDATION_LOG (
        log_id INTEGER PRIMARY KEY,
        user_id INTEGER,
        request_barcode TEXT,
        request_type TEXT,
        recommended_products TEXT,
        algorithm_version TEXT,
        llm_prompt TEXT,
        llm_response TEXT,
        llm_analysis TEXT,
        processing_time_ms INTEGER,
        total_candidates INTEGER,
        filtered_candidates INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES USER(user_id)
    )
    """)
    
    # 插入测试数据
    # 1. 插入测试用户
    cursor.execute("""
    INSERT OR IGNORE INTO USER (user_id, username, email, age, gender, height_cm, weight_kg, 
                               activity_level, nutrition_goal, daily_calories_target, 
                               daily_protein_target, daily_carb_target, daily_fat_target)
    VALUES (1, 'test_user', 'test@example.com', 30, 'male', 175, 70, 'moderate', 
            'maintain', 2200, 100, 250, 70)
    """)
    
    # 2. 插入测试商品
    cursor.execute("""
    INSERT OR IGNORE INTO PRODUCT (barcode, name, brand, category, energy_kcal_100g, 
                                  proteins_100g, fat_100g, sugars_100g)
    VALUES 
    ('5449000000996', 'Coca-Cola Classic 500ml', 'Coca-Cola', 'Beverages', 42, 0, 0, 10.6),
    ('7622210951717', 'White Bread', 'Generic', 'Bread', 265, 8.5, 3.2, 3.5)
    """)
    
    # 3. 插入测试过敏原
    cursor.execute("""
    INSERT OR IGNORE INTO ALLERGEN (allergen_id, name, category, is_common, description)
    VALUES 
    (1, 'milk', 'dairy', 1, '乳制品过敏'),
    (2, 'nuts', 'nuts', 1, '坚果过敏')
    """)
    
    # 4. 插入用户过敏原关联
    cursor.execute("""
    INSERT OR IGNORE INTO USER_ALLERGEN (user_id, allergen_id, severity_level, confirmed)
    VALUES (1, 1, 2, 1)
    """)
    
    # 提交更改
    conn.commit()
    conn.close()
    
    print("数据库初始化完成！")

if __name__ == "__main__":
    init_database() 